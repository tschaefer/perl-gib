package Perl::Gib::App::CLI::Test;

##! #[ignore(item)]
##! Perl::Gib command line application extension `test`.

use strict;
use warnings;

use Moose::Role;

### Perl::Gib configuration options, see [Perl::Gib::Config](../Config.html).
has 'action_options' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { return {}; },
);

### Action information.
has 'action_info' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'Testing',
    init_arg => undef,
);

### Run tests.
sub execute_action {
    my $self = shift;

    $self->controller->test();

    return;
}

1;
