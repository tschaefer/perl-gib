package Perl::Gib::Exception::AttributeIsIgnoredByComment;

##! #[ignore(item)]

use strict;
use warnings;

use Moose;
extends 'Perl::Gib::Exception';
with 'Perl::Gib::Exception::ItemIsIgnoredByComment';

sub _build_item {
    my $self = shift;

    return 'Attribute';
}

__PACKAGE__->meta->make_immutable;

1;
