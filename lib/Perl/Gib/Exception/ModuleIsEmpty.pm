package Perl::Gib::Exception::ModuleIsEmpty;

##! #[ignore(item)]

use strict;
use warnings;

use Moose;
extends 'Perl::Gib::Exception';

has 'file' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub _build_message {
    my $self = shift;

    return sprintf "Module is empty: '%s'", $self->file;
}

__PACKAGE__->meta->make_immutable;

1;
