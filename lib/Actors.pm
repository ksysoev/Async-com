package Actors;
use strict;

use Data::Dumper;

use Carp qw(confess);

our $__context;
our $__app_context;

use Exporter 'import';
our @EXPORT = qw(actor case app);

sub app {
    my ($name, $context) = @_;
    local $__app_context;
    $__app_context = {};

    $context->();
    return App->new($__app_context);
}

sub actor {
    my ($name, $context) = @_;
    local $__context;
    $__context = {};
    $context->();
    $__context->{name} = $name;
    $__app_context->{actors}{$name} = Actor->new($__context);

    return $__app_context->{actors}{$name};
}

sub case {
    my $msg_name = shift;
    my $code = pop;
    my @named_args = @_;
    $__context->{cases}{$msg_name} = { code => $code, named_args => \@named_args };
}


package Actor;
use Bus;

sub new {
    my ($cls, $params) = @_;

    my $self = {
        name  => $params->{name},
        cases => $params->{cases} || {},
    };

    bless $self, $cls;

    Bus->subscribe( $self, keys %{$params->{cases}} );
    return $self;
}

sub subscribe {
    my $code = pop;
    my ($self, $msg_name, @named_args) = @_;

    $self->{cases}{$msg_name} = { code => $code, named_args => \@named_args };

    Bus->subscribe( $self, $msg_name );

    return $self;
}

sub name { shift->{name} }

sub send {
    my ( $self,$msg, $args ) = @_;

    Bus->emit($msg, $args, $self);
}

sub emit {
    my ( $self, $msg, $args, $sender ) = @_;

    return unless exists $self->{cases}{$msg};
    
    my %h_args = %{ $args // {} };
    my $case = $self->{cases}{$msg};

    my @named_args = delete @h_args{ @{ $case->{named_args} } };

    return $self->{cases}{$msg}{code}->($self, @named_args, \%h_args, $sender);
}


1;

package App;
sub new {
    my ($cls, $params) = @_;
    my $self = {
        actors => $params->{actors} || {},
    };

    bless $self, $cls;

    return $self;
}

sub get_actor {
    my ($self, $name) = @_;
    return $self->{actors}{$name}
}

sub subscribe {
    my ($self, $case, $cb) = @_;

    my $anon_actor = Actor->new({
        name => 'anon' . rand,
        cases => { $case => { code => $cb, named_args => [] } },
    });

    return $anon_actor;
}

sub send {
    my ( $self,$msg, $args ) = @_;

    Bus->emit($msg, $args);
}
