package Perl::Gib::Module;

##! [Parse](https://metacpan.org/pod/PPI) Perl module and process data for
##! documentation and tests.

use strict;
use warnings;

use Moose;
use MooseX::Types::Path::Tiny qw(AbsFile);

use Moose::Util qw(apply_all_roles);

use Carp qw(croak);
use English qw(-no_match_vars);
use Mojo::Template;
use Path::Tiny;
use PPI;
use Pod::HTML2Pod;
use Text::Markdown qw(markdown);
use Try::Tiny;

use Perl::Gib::Config;
use Perl::Gib::Item::Package;
use Perl::Gib::Item::Subroutine;
use Perl::Gib::Util qw(throw_exception);

no warnings "uninitialized";

### #[ignore(item)]
### Perl::Gib configuration object. [optional]
has 'config' => (
    is       => 'ro',
    isa      => 'Perl::Gib::Config',
    default  => sub { Perl::Gib::Config->instance() },
    init_arg => undef,
);

### Path to Perl module file. [required]
has 'file' => (
    is       => 'ro',
    isa      => AbsFile,
    required => 1,
    coerce   => 1,
);

### #[ignore(item)]
### Document Object Model of Perl module.
has 'dom' => (
    is       => 'ro',
    isa      => 'PPI::Document',
    lazy     => 1,
    builder  => '_build_dom',
    init_arg => undef,
);

### #[ignore(item)]
### Package item object.
has 'package' => (
    is       => 'ro',
    isa      => 'Perl::Gib::Item::Package',
    lazy     => 1,
    builder  => '_build_package',
    init_arg => undef,
);

### #[ignore(item)]
### List of subroutine items.
has 'subroutines' => (
    is       => 'ro',
    isa      => 'Maybe[ArrayRef[Perl::Gib::Item::Subroutine]]',
    lazy     => 1,
    builder  => '_build_subroutines',
    init_arg => undef,
);

### Parse file with PPI and return DOM. Prune empty lines and
### [Perl::Critic](https://metacpan.org/pod/Perl::Critic) annotation
### comments.
sub _build_dom {
    my $self = shift;

    my $dom = PPI::Document->new( $self->file->canonpath, readonly => 1 );
    throw_exception( 'ModuleIsEmpty', file => $self->file->canonpath() )
      if ( !$dom );
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

### Find package statement and belonging comment block in DOM and create
### equivalent object. If module does not contain a package exception is
### thrown. By default module with pseudo function `#[ignore(item)]` in
### package comment block are ignored.
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

    throw_exception( 'FileIsNotAPerlModule', file => $self->file->canonpath() )
      if ( !@fragment );

    return Perl::Gib::Item::Package->new( fragment => \@fragment, );
}

### Find subroutine statements and belonging comment block in DOM and create
### equivalent object. By default private subroutines and subroutines starting
### with a pseudo function `#[ignore(item)]` in comment block are ignored.
sub _build_subroutines {
    my $self = shift;

    my @elements = $self->dom->elements();

    my @subroutines;
    foreach my $element (@elements) {
        if ( $element->isa('PPI::Statement::Sub') ) {

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
                    Perl::Gib::Item::Subroutine->new( fragment => \@fragment, );
                }
                catch {
                    for my $exception (
                        qw(
                        SubroutineIsIgnoredByComment
                        SubroutineIsPrivate
                        SubroutineIsUndocumented
                        )
                      )
                    {
                        return
                          if (
                            $_->isa( 'Perl::Gib::Exception::' . $exception ) );
                    }

                    croak($_);
                };
                last if ( !$sub );

                push @subroutines, $sub;
                last;
            }
        }
    }

    return \@subroutines;
}

### #[ignore(item)]
### Trigger DOM parsing and item creation. Apply role
### `Perl::Gib::Module::Moose` if `Moose` or `Moo` or their respective Role
### usage is found.
sub BUILD {
    my $self = shift;

    $self->dom;
    $self->package;
    $self->subroutines;

    my $has_moose = $self->dom->find_first(
        sub {
            my ( $node, $element ) = @_;

            return 1
              if ( $element->isa('PPI::Statement::Include')
                && $element->module =~
                /^Moose$|^Moose::Role$|^Moo$|^Moo::Role$/ );

            return 0;
        }
    );

    if ($has_moose) {
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

### Provide documentation in Pod.
###
### ```
###     my $module = Perl::Gib::Module->new( { file => 'lib/Perl/Gib/Module.pm' } );
###
###     my $pod   = $module->to_pod();
###     my @lines = split /\n/, $pod;
###     is( $lines[0], '=head1 Perl::Gib::Module', 'Pod documentation' );
### ```
sub to_pod {
    my $self = shift;

    my $html = $self->to_html;

    # see Pod::HTML2POD 'Use "<h1>" and "<h2>" for headings.'
    $html =~ s/<h2>/<h1>/gm;
    $html =~ s/<h3>/<h2>/gm;

    return Pod::HTML2Pod::convert( content => $html, a_href => 1 );
}

### Generate and run Perl module test scripts with
### [prove](https://metacpan.org/pod/distribution/Test-Harness/bin/prove).
### Optional add `$library` to the path for the tests.
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

    my $cmd = sprintf "prove %s --verbose %s",
      $library ? ( sprintf "--lib %s", $library ) : '', $file->stringify;
    system split / /, $cmd;
    my $rc = $CHILD_ERROR >> 8;

    throw_exception( 'ModuleTestFailed', name => $self->package->statement )
      if ($rc);

    return;
}

__PACKAGE__->meta->make_immutable;

1;
