package Perl::Gib::Item::Subroutine;

##! #[ignore(item)]

use strict;
use warnings;

use Moose;
with qw(Perl::Gib::Item);

use Carp qw(croak);

no warnings "uninitialized";

has 'test' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    lazy     => 1,
    builder  => '_build_test',
    init_arg => undef,
);

sub _build_statement {
    my $self = shift;

    my @params;
    my $get_params = sub {
        my $block = $self->fragment->[0]->block;
        return if ( !$block );

        my $variable = $block->find_first('PPI::Statement::Variable');
        return if ( !$variable );

        @params = $variable->variables;
    };
    $get_params->();

    return sprintf "sub %s(%s)", $self->fragment->[0]->name, join ', ', @params;
}

sub _build_description {
    my $self = shift;

    my @fragment = @{ $self->fragment };
    shift @fragment;

    croak( sprintf "Subroutine ignored by comment: %s", $self->statement )
      if ( $fragment[0] =~ /#\[ignore\(item\)\]/ );

    my $description;
    foreach my $line (@fragment) {
        $line =~ s/^### ?//;
        $line = "\n" if ( $line =~ /^```\s$/ );
        $description .= $line;
    }

    $description =~ s/\s+$//g;

    return $description;
}

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

after 'BUILD' => sub {
    my $self = shift;

    $self->test;

    return;
};

__PACKAGE__->meta->make_immutable;

1;
