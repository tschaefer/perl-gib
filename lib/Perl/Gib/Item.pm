package Perl::Gib::Item;

##! #[ignore(item)]
##! This role is the base for all item classes.
##!
##! * package
##! * subroutine
##! * attribute
##! * modifier

use strict;
use warnings;

use Moose::Role;

use Perl::Gib::Config;

requires qw(_build_statement _build_description);

### Perl::Gib configuration object. [optional]
has 'config' => (
    is       => 'ro',
    isa      => 'Perl::Gib::Config',
    default  => sub { Perl::Gib::Config->instance() },
    init_arg => undef,
);

### List of DOM fragments with statement and comment block. [required]
has 'fragment' => (
    is       => 'ro',
    isa      => 'ArrayRef[PPI::Element]',
    required => 1,
);

### Statement as string.
has 'statement' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_build_statement',
    init_arg => undef,
);

### Purged comment block as string.
has 'description' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    lazy     => 1,
    builder  => '_build_description',
    init_arg => undef,
);

### Code line number.
has 'line' => (
    is       => 'ro',
    isa      => 'Maybe[Int]',
    lazy     => 1,
    builder  => '_build_line',
    init_arg => undef,
);

### Trigger item creation.
sub BUILD {
    my $self = shift;

    $self->statement;
    $self->description;
    $self->line;

    return;
}

### Set code line number of statement.
sub _build_line {
    my $self = shift;

    return $self->fragment->[0]->line_number;
}

1;
