package Perl::Gib::Exception::ModifierIsUndocumented;

##! #[ignore(item)]

use strict;
use warnings;

use Moose;
extends 'Perl::Gib::Exception';
with 'Perl::Gib::Exception::ItemIsUndocumented';

sub _build_item {
    my $self = shift;

    return 'Modifier';
}

__PACKAGE__->meta->make_immutable;

1;
