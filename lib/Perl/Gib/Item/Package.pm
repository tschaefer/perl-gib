package Perl::Gib::Item::Package;

##! #[ignore(item)]
##! This class implements role `Perl::Gib::Item` and provides information
##! about a package.

use strict;
use warnings;

use Moose;
with qw(Perl::Gib::Item);

use Carp qw(croak);

no warnings "uninitialized";

### Create item statement string.
sub _build_statement {
    my $self = shift;

    return $self->fragment->[0]->namespace;
}

### Create item description string by parsing comment block. By default
### packages starting with a pseudo function `#[ignore(item)]` in comment
### block are ignored; the class will croak.
sub _build_description {
    my $self = shift;

    my @fragment = @{ $self->fragment };
    shift @fragment;

    if ( $fragment[0] =~ /#\[ignore\(item\)\]/ ) {
        croak( sprintf "Package / Module ignored by comment: %s",
            $self->statement )
          if ( !$self->config->document_ignored_items );

        shift @fragment;
    }

    my $description;
    foreach my $line (@fragment) {
        $line =~ s/^##! ?//;
        $description .= $line;
    }

    $description =~ s/\s+$//g;

    croak( sprintf "Package / Module documentation is empty: %s", $self->statement )
      if ( $self->config->ignore_undocumented_items && !$description );

    return $description;
}

__PACKAGE__->meta->make_immutable;

1;
