package Perl::Gib::Item::Package;

##! #[ignore(item)]

use strict;
use warnings;

use Moose;
with qw(Perl::Gib::Item);

use Carp qw(croak);

no warnings "uninitialized";

sub _build_statement {
    my $self = shift;

    return $self->fragment->[0]->namespace;
}

sub _build_description {
    my $self = shift;

    my @fragment = @{ $self->fragment };
    shift @fragment;

    my $description;
    foreach my $line (@fragment) {
        $line =~ s/^##! ?//;

        croak( sprintf "Package / Module ignored by comment: %s",
            $self->statement )
          if ( $fragment[0] =~ /#\[ignore\(item\)\]/ );

        $description .= $line;
    }

    $description =~ s/\s+$//g;

    return $description;
}

__PACKAGE__->meta->make_immutable;

1;
