package Perl::Gib::App::CLI::Test;

##! #[ignore(item)]

use strict;
use warnings;

use Moose::Role;

has 'action_options' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { return {}; },
);

has 'action_info' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'Testing',
    init_arg => undef,
);

sub execute_action {
    my $self = shift;

    $self->controller->test();

    return;
}

1;
