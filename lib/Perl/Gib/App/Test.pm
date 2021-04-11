package Perl::Gib::App::Test;

use strict;
use warnings;

use Moose::Role;

has 'action_options' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { return {}; },
);

has 'action_info' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Testing',
);

sub execute_action {
    my $self = shift;

    $self->controller->test();

    return;
}

1;
