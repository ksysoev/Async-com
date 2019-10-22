package RPC;
use Actors;

our $app = app rpc => sub {
    actor account_service => sub {
        my $USER_DB = {
            user1 => {reg_date => '12.12.12'},
        };
    
        case get_user_info => qw(user_id reply_to), sub {
            my ($self, $user_id, $reply_to) = @_;

            my $user = $USER_DB->{$user_id};
            $self->send($reply_to => $user);
        }
    }
}