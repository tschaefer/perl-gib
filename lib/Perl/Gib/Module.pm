package Perl::Gib::Module;

##! [Parse](https://metacpan.org/pod/PPI) Perl module and process data for
##! documentation and tests.

use strict;
use warnings;

use Moose;

use Moose::Util qw(apply_all_roles);

use Carp qw(croak);
use English qw(-no_match_vars);
use Mojo::Template;
use Path::Tiny;
use PPI;
use Text::Markdown qw(markdown);
use Try::Tiny;

use Perl::Gib::Item::Package;
use Perl::Gib::Item::Subroutine;

no warnings "uninitialized";

### Path to Perl module file. [required]
has 'file' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

### #[ignore(item)]
has 'dom' => (
    is       => 'ro',
    isa      => 'PPI::Document',
    lazy     => 1,
    builder  => '_build_dom',
    init_arg => undef,
);

### #[ignore(item)]
has 'package' => (
    is       => 'ro',
    isa      => 'Perl::Gib::Item::Package',
    lazy     => 1,
    builder  => '_build_package',
    init_arg => undef,
);

### #[ignore(item)]
has 'subroutines' => (
    is       => 'ro',
    isa      => 'Maybe[ArrayRef[Perl::Gib::Item::Subroutine]]',
    lazy     => 1,
    builder  => '_build_subroutines',
    init_arg => undef,
);

### Document private items.
has 'document_private_items' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub _build_dom {
    my $self = shift;

    my $dom = PPI::Document->new( $self->file, readonly => 1 );
    croak( sprintf "Module is empty: %s", $self->file ) if ( !$dom );
    $dom->index_locations();
    $dom->prune('PPI::Token::Whitespace');
    $dom->prune(
        sub {
            my ( $node, $element ) = @_;

            return 1
              if ( $element->isa('PPI::Token::Comment')
                && $element =~ /## no critic/ );
            return 0;
        }
    );

    return $dom;
}

sub _build_package {
    my $self = shift;

    my @elements = $self->dom->elements();

    my @fragment;
    my $done;
    foreach my $element (@elements) {
        if ( $element->isa('PPI::Statement::Package') ) {
            push @fragment, $element;

            my $next = $element->next_sibling;
            while ($next) {
                if (   $next->isa('PPI::Token::Comment')
                    && $next =~ /^##!/ )
                {
                    push @fragment, $next;
                    $next = $next->next_sibling;
                    next;
                }
                $done = 1;
                last;
            }
        }
        last if ($done);
    }

    croak( sprintf "Module does not contain package: %s", $self->file )
      if ( !@fragment );

    return Perl::Gib::Item::Package->new( fragment => \@fragment );
}

sub _build_subroutines {
    my $self = shift;

    my @elements = $self->dom->elements();

    my @subroutines;
    foreach my $element (@elements) {
        if ( $element->isa('PPI::Statement::Sub') ) {

            next
              if ( $element->name =~ /^_/
                && !$self->document_private_items );

            my @fragment;
            my $previous = $element->previous_sibling();
            while ($previous) {
                if (   $previous->isa('PPI::Token::Comment')
                    && $previous =~ /^###/ )
                {
                    push @fragment, $previous;
                    $previous = $previous->previous_sibling();
                    next;
                }

                push @fragment, $element;
                @fragment = reverse @fragment;

                my $sub = try {
                    Perl::Gib::Item::Subroutine->new( fragment => \@fragment );
                }
                catch {
                    croak($_) if ( $_ !~ /ignored by comment/ );
                };
                last if ( !$sub );

                push @subroutines, $sub;
                last;
            }
        }
    }

    return \@subroutines;
}

sub _has_moose {
    my $self = shift;

    return $self->dom->find_first(
        sub {
            my ( $node, $element ) = @_;

            return 1
              if ( $element->isa('PPI::Statement::Include')
                && $element->module =~
                /^Moose$|^Moose::Role$|^Moo$|^Moo::Role$/ );

            return 0;
        }
    );
}

### #[ignore(item)]
sub BUILD {
    my $self = shift;

    $self->dom;
    $self->package;
    $self->subroutines;

    if ( $self->_has_moose() ) {
        apply_all_roles( $self, 'Perl::Gib::Module::Moose' );
        $self->attributes;
        $self->modifiers;
    }

    return;
}

### Provide documentation in Markdown.
###
### ```
###     my $module = Perl::Gib::Module->new( { file => 'lib/Perl/Gib/Module.pm' } );
###
###     my $markdown = $module->to_markdown();
###     my @lines    = split /\n/, $markdown;
###     is( $lines[0], '# Perl::Gib::Module', 'Markdown documentation' );
### ```
sub to_markdown {
    my $self = shift;

    my $template = <<'TEMPLATE';
# <%= $package->statement %>

% if ($package->description) {
<%= $package->description %>
% }

% if (@{$subroutines}) {
## Subroutines

% foreach my $sub (@{$subroutines}) {
### `<%= $sub->statement %>; #<%= $sub->line %>`

% if ($sub->description) {
<%= $sub->description %>
% }

% }
% }
TEMPLATE

    return Mojo::Template->new()->vars(1)
      ->render( $template,
        { package => $self->package, subroutines => $self->subroutines } );
}

### Provide documentation in HTML.
###
### ```
###     my $module = Perl::Gib::Module->new( { file => 'lib/Perl/Gib/Module.pm' } );
###
###     my $html = $module->to_html();
###     my @lines    = split /\n/, $html;
###     is( $lines[0], '<h1>Perl::Gib::Module</h1>', 'HTML documentation' );
### ```
sub to_html {
    my $self = shift;

    return markdown( $self->to_markdown() );
}

### Generate and run Perl module test script with
### [prove](https://metacpan.org/pod/distribution/Test-Harness/bin/prove).
###
### #### Example of produced module test script
###
###     use Animal::Horse;
###     use Test::More;
###
###     subtest 'trot' => sub {
###         ok(1);
###     };
###     subtest 'gallop' {
###         ok(2 > 1);
###     };
###
###     done_testing();
###
### `$library` path of Perl module, default is **lib**.
sub run_test {
    my ( $self, $library ) = @_;

    my %tests;
    foreach my $sub ( @{ $self->subroutines } ) {
        if ( defined $sub->test ) {
            my ($name) = $sub->statement =~ /sub (.+)\(/;
            $tests{$name} = $sub->test;
        }
    }
    return if ( !%tests );

    my $template = <<'TEMPLATE';
use <%= $package %>;
use Test::More;

printf "## Moduletest: %s\n", "<%= $package %>";

% foreach my $name (keys %{$tests}) {
subtest '<%= $name %>' => sub {
    <%= $tests->{$name} %>
};
% }

done_testing();
TEMPLATE

    my $test =
      Mojo::Template->new()->vars(1)
      ->render( $template,
        { package => $self->package->statement, tests => \%tests } );

    my $file = Path::Tiny->tempfile();
    $file->spew($test);

    $library ||= path('lib')->absolute;
    my $cmd = sprintf "prove --lib %s --verbose %s", $library, $file->stringify;
    system split / /, $cmd;
    my $rc = $CHILD_ERROR >> 8;

    croak( sprintf "Module '%s' test failed", $self->package->statement )
      if ($rc);

    return;
}

__PACKAGE__->meta->make_immutable;

1;
