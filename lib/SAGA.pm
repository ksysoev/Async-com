package SAGA;
use Actors;

our $app = app saga_pattern => sub {
    actor order_service => sub {
        my $counter = 0;
        my $contracts = {};
        case buy_contract => qw(session), sub {
            my ($self, $session) = @_;
            my $id = ++$counter;
            $contracts->{$id}{status} = 'pending';
            $self->send( contract_created => { id => $id , session => $session } );
        };
    
        case contract_valid => qw(id), sub {
            my ($self, $id) = @_;

            return if $contracts->{$id}{status} eq 'rejected';
            $contracts->{$id}{status} = 'valid'
        };
    
        case contract_rejected => qw(id), sub {
            my ($self, $id) = @_;
            $contracts->{$id}{status} = 'rejected'
        };
    
        case contract_paid => qw(id), sub {
            my ($self, $id) = @_;
            $contracts->{$id}{status} = 'paid'
        };
    
        case get_status => qw(id reply_to), sub {
            my ($self, $id, $replay_to) = @_;
            $self->send($replay_to => { status => ($contracts->{$id}{status} // 'not_found') });
        };
    };
    
    actor billing_service => sub {
        my $ledger = {};
    
        case contract_created => sub {
            my ($self, $args) = @_;

            my $success = 1;
    
            if ( $success ) {
                $ledger->{$args->{id}} = 'reserved';
            } else {
                $self->send( contract_rejected => $args );           
            }
        };
    
        case contract_rejected => sub {
            my ($self, $args) = @_;
            delete $ledger->{$args->{id}}
        };
    
        case contract_valid => sub {
            my ($self, $args) = @_;
            return unless $ledger->{$args->{id}};
            $ledger->{$args->{id}} = 'paid';
            $self->send( contract_paid => $args );
        };
    };
    
    actor validator => sub {
        case contract_created => sub {
            my ($self, $args) = @_;
    
            my $success = 1;
    
            if ( $success ) {
                $self->send( contract_valid  => $args );
            } else {
                $self->send( contract_rejected => $args );           
            }        
        };
    
    };
};