package Perl::Gib::Exception::ItemIsPrivate;

##! #[ignore(item)]

use strict;
use warnings;

use Moose::Role;

requires '_build_item';

has 'item' => (
    is      => 'ro',
    isa     => 'Str',
    builder => '_build_item',
    lazy    => 1,
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub _build_message {
    my $self = shift;

    return sprintf "%s is private: '%s'", $self->item, $self->name;
}

1;
