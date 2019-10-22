package Bus;
use List::Util;


my %subscription =();

sub subscribe {
    my ($cls, $s, @events) = @_; 
    $subscription{$_}{$s->name} //= $s for @events;
    return 1;
}

my $lock = 0;
my @queue;
sub emit {
    my ($cls, $event, $args, $sender) = @_;
    push @easy_queue, [$event, $args, $sender];
    return if $lock;

    $lock = 1;
    
    while (($event, $args, $sender) = @{ shift(@easy_queue) }) {
        next unless exists $subscription{$event};
        $_->emit($event, $args, $sender) for values %{$subscription{$event}};
    }

    $lock = 0 ;

    return 1;
}

sub wipe {
    %subscription = ()
}


1;