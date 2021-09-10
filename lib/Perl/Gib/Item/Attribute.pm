package Perl::Gib::Item::Attribute;

##! #[ignore(item)]
##! This class implements role `Perl::Gib::Item` and provides information
##! about a Moose attribute.

use strict;
use warnings;

use Moose;
with qw(Perl::Gib::Item);

use Perl::Gib::Util qw(throw_exception);

no warnings "uninitialized";

### Create item statement string. By default private attributes are ignored;
### the class will croak.
sub _build_statement {
    my $self = shift;

    my $fragment = $self->fragment->[0];

    my $name = $fragment->child(1)->string;
    throw_exception( 'AttributeIsPrivate', name => $name )
      if ( $name =~ /^_/ && !$self->config->document_private_items );

    my @elements  = $fragment->elements;
    my $statement = join ' ', @elements[ 0, 1 ];

    return $statement;
}

### Create item description string by parsing comment block. By default
### attributes starting with a pseudo function `#[ignore(item)]` in comment
### block are ignored; the class will croak.
sub _build_description {
    my $self = shift;

    my @fragment = @{ $self->fragment };
    shift @fragment;

    if ( $fragment[0] =~ /#\[ignore\(item\)\]/ ) {
        throw_exception( 'AttributeIsIgnoredByComment',
            name => $self->statement )
          if ( !$self->config->document_ignored_items );

        shift @fragment;
    }

    my $description;
    foreach my $line (@fragment) {
        $line =~ s/^### ?//;
        $description .= $line;
    }

    $description =~ s/\s+$//g;

    throw_exception( 'AttributeIsUndocumented', name => $self->statement )
      if ( $self->config->ignore_undocumented_items && !$description );

    return $description;
}

__PACKAGE__->meta->make_immutable;

1;
