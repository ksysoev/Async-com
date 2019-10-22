package Notification;
use Actors;

use Data::Dumper;


our $app = app notification => sub {
    actor account_service => sub {
        my $USER_DB = {
            user1 => { city => 'Cyberjaya' },
        };
    
        case change_city => qw(user_id new_city), sub {
            my ($self, $user_id, $new_city) = @_;

            $USER_DB->{$user_id}{city} = $new_city;

            $self->send(notifications => {
                user_id  => $user_id,
                msg      => "City is changed"
            });
        }
    }
}