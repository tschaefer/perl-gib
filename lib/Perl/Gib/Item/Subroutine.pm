package Perl::Gib::Item::Subroutine;

##! #[ignore(item)]
##! This class implements role `Perl::Gib::Item` and provides information
##! about a subroutine.

use strict;
use warnings;

use Moose;
with qw(Perl::Gib::Item);

use Perl::Gib::Util qw(throw_exception);

no warnings "uninitialized";

### Test script.
has 'test' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    lazy     => 1,
    builder  => '_build_test',
    init_arg => undef,
);

### Create item statement string. By default private subroutines are ignored;
### the class will croak.
sub _build_statement {
    my $self = shift;

    my $name = $self->fragment->[0]->name;
    throw_exception( 'SubroutineIsPrivate', name => $name )
      if ( $name =~ /^_/ && !$self->config->document_private_items );

    my @params;
    my $get_params = sub {
        my $block = $self->fragment->[0]->block;
        return if ( !$block );

        my $statement = $block->find_first('PPI::Statement::Variable');
        return if ( !$statement );

        @params = $statement->variables;
    };
    $get_params->();

    return sprintf "sub %s(%s)", $self->fragment->[0]->name, join ', ', @params;
}

### Create item description string by parsing comment block. By default
### subroutines starting with a pseudo function `#[ignore(item)]` in comment
### block are ignored; the class will croak.
sub _build_description {
    my $self = shift;

    my @fragment = @{ $self->fragment };
    shift @fragment;

    if ( $fragment[0] =~ /#\[ignore\(item\)\]/ ) {
        throw_exception( 'SubroutineIsIgnoredByComment',
            name => $self->statement )
          if ( !$self->config->document_ignored_items );

        shift @fragment;
    }

    my $description;
    foreach my $line (@fragment) {
        $line =~ s/^### ?//;
        $line = "\n" if ( $line =~ /^```\s$/ );
        $description .= $line;
    }

    $description =~ s/\s+$//g;

    throw_exception( 'SubroutineIsUndocumented', name => $self->statement )
      if ( $self->config->ignore_undocumented_items && !$description );

    return $description;
}

### Create test script by parsing comment block part with three apostrophe as
### limiter.
sub _build_test {
    my $self = shift;

    my @fragment = @{ $self->fragment };
    shift @fragment;

    my $code;
    my $limiter = 0;
    foreach my $line (@fragment) {
        $line =~ s/^### ?//;
        if ($limiter) {
            if ( $line =~ /^```\s$/ ) {
                $limiter = 0;
                next;
            }
            $line =~ s/^\s+//g;
            $code .= $line;
        }
        $limiter = 1 if ( $line =~ /^```\s$/ );
    }
    return if ($limiter);

    $code =~ s/\s+$//;

    return $code;
}

### Trigger test script build.
after 'BUILD' => sub {
    my $self = shift;

    $self->test;

    return;
};

__PACKAGE__->meta->make_immutable;

1;
