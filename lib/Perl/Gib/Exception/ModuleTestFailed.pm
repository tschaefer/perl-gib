package Perl::Gib::Exception::ModuleTestFailed;

##! #[ignore(item)]

use strict;
use warnings;

use Moose;
extends 'Perl::Gib::Exception';

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub _build_message {
    my $self = shift;

    return sprintf "Perl module test failed: '%s'", $self->name;
}

__PACKAGE__->meta->make_immutable;

1;