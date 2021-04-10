package Perl::Gib::App::Test;

use strict;
use warnings;

use Moose::Role;

has 'info' => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    builder => '_build_info',
);

sub _build_info {
    my $self = shift;

    return 'Testing';
}

sub _execute {
    my $self = shift;

    $self->perlgib->test();

    return;
}

1;
