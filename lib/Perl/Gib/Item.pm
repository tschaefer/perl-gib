package Perl::Gib::Item;

##! #[ignore(item)]

use strict;
use warnings;

use Moose::Role;

requires qw(_build_statement _build_description);

has 'fragment' => (
    is       => 'ro',
    isa      => 'ArrayRef[PPI::Element]',
    required => 1,
);

has 'statement' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_build_statement',
    init_arg => undef,
);

has 'description' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    lazy     => 1,
    builder  => '_build_description',
    init_arg => undef,
);

has 'line' => (
    is       => 'ro',
    isa      => 'Maybe[Int]',
    lazy     => 1,
    builder  => '_build_line',
    init_arg => undef,
);

sub BUILD {
    my $self = shift;

    $self->statement;
    $self->description;

    return;
}

sub _build_line {
    my $self = shift;

    return $self->fragment->[0]->line_number;
}

1;
