package Perl::Gib::Item::Attribute;

##! #[ignore(item)]

use strict;
use warnings;

use Moose;
with qw(Perl::Gib::Item);

use Carp qw(croak);

no warnings "uninitialized";

sub _build_statement {
    my $self = shift;

    my $fragment = $self->fragment->[0];
    my @elements = $fragment->elements;

    my $statement = join ' ', @elements[ 0, 1 ];

    return $statement;
}

sub _build_description {
    my $self = shift;

    my @fragment = @{ $self->fragment };
    shift @fragment;

    croak( sprintf "Attribute ignored by comment: %s", $self->statement )
      if ( $fragment[0] =~ /#\[ignore\(item\)\]/ );

    my $description;
    foreach my $line (@fragment) {
        $line =~ s/^### ?//;
        $description .= $line;
    }

    $description =~ s/\s+$//g;

    return $description;
}

__PACKAGE__->meta->make_immutable;

1;
