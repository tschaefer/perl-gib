package Perl::Gib::Exception::FileIsNotAPerlModule;

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

    return sprintf "File is not a Perl module: '%s'", $self->file;
}

__PACKAGE__->meta->make_immutable;

1;
