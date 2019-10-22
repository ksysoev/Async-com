package CQRS;
use Actors;

our $app = app CQSR => sub {
    actor order_write_model => sub {
        my $counter = 0;

        case buy_something => sub {
            my ($self) = @_;
            my $id = ++$counter;
            $self->send( something_created => { id => $id , status => 'new' } );
        };
    };
    
    actor order_view_model => sub {
        my %ORDERS_DB = ();
    
        case something_created => sub {
            my ($self, $args) = @_;
            $ORDERS_DB{ $args->{id} } = $args;
        };

        case get_something => qw(id reply_to), sub {
            my ($self, $id, $reply_to) = @_;
            $self->send($reply_to => $ORDERS_DB{ $id } );
        };
    };
    
    actor order_statistic_model => sub {
        my %STAT_DB = (new_something => 0);
        case something_created => qw(status), sub {
            my ($self, $status) = @_;
            $STAT_DB{new_something}++ if $status eq 'new';
        };

        case get_statistic => qw(reply_to), sub {
            my ($self, $reply_to) = @_;

            $self->send($reply_to => \%STAT_DB);
        };
    };
};