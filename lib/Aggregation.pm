package Aggregation;

use strict;
use warnings;

use Actors;
use Data::Dumper;

our $app = app agregation => sub {
    actor aggregation_service => sub {
        case get_user_profile => qw(user_id reply_to), sub {
            my ($self, $user_id, $reply_to) = @_;
            my $reply_queue = 'queue_' . rand;
            my %profile;
            $self->subscribe($reply_queue => sub {
                my ($self, $data) = @_;
                @profile{keys %$data} = values %$data;

                return if !$profile{balance} 
                       && !$profile{open_contracts};
                $self->send($reply_to => \%profile);
            });

            $self->send(get_balance => {
                user_id  => $user_id,
                reply_to => $reply_queue,
            });

            $self->send(get_open_contracts => {
                user_id  => $user_id,
                reply_to => $reply_queue,
            });
        }
    };

    actor billing_service => sub {
        my $ACCOUNT_DB = { user1 => 100 };

        case get_balance => qw(user_id reply_to), sub {
            my ($self, $user_id, $reply_to) = @_;

            my $amount = $ACCOUNT_DB->{$user_id};
            $self->send($reply_to => {user_id => $user_id, balance => $amount});
        }
    };

    actor order_service => sub {
        my $CLIENT_DB = { user1 => ['test_contract'] };

        case get_open_contracts => qw(user_id reply_to), sub {
            my ($self, $user_id, $reply_to) = @_;

            my $open_contracts = $CLIENT_DB->{$user_id};
            $self->send($reply_to => {user_id => $user_id, open_contracts => $open_contracts});
        }
    };
}