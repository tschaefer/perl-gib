package Perl::Gib::App;

use strict;
use warnings;

use Moose;
use Moose::Util qw(apply_all_roles);

use Carp qw(croak);
use Getopt::Long qw(:config require_order);
use List::Util qw(any);
use Pod::Usage;
use Scalar::Util;
use Term::ANSIColor;
use Time::HiRes;
use Try::Tiny;

use Perl::Gib;
use Perl::Gib::Config;

$Term::ANSIColor::AUTORESET = 1;

has 'action' => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_action',
);

has 'config' => (
    is       => 'ro',
    isa      => 'Perl::Gib::Config',
    lazy     => 1,
    builder  => '_build_config',
    init_arg => undef,
);

has 'controller' => (
    is       => 'ro',
    isa      => 'Perl::Gib',
    lazy     => 1,
    builder  => '_build_controller',
    init_arg => undef,
);

has 'options' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_options',
);

sub _build_action {
    my $self = shift;

    my $action = $ARGV[0];
    return if ( !$action );

    $action =~ s/-/_/g;

    croak( sprintf "Unknown action: %s", $action )
      if ( !any { $_ eq $action } qw(doc test) );

    shift @ARGV;

    return $action;
}

sub _build_options {
    my $self = shift;

    my %options;

    GetOptions(
        "library-path=s" => \$options{'library_path'},
        "library-name=s" => \$options{'library_name'},
        "help|h"         => \$options{'help'},
        "man|m"          => \$options{'man'},
        "version|v"      => \$options{'version'},
    ) or croak();

    foreach my $key ( keys %options ) {
        delete $options{$key} if ( !$options{$key} );
    }
    my $count = keys %options;

    croak('Too many options')
      if ( ( $options{'help'} || $options{'man'} || $options{'version'} )
        && $count > 1 );

    return \%options;
}

sub _build_config {
    my $self = shift;

    return Perl::Gib::Config->initialize( %{ $self->options },
        %{ $self->action_options } );
}

sub _build_controller {
    my $self = shift;

    return Perl::Gib->new();
}

sub help {
    my $self = shift;

    pod2usage(
        -exitval  => 'NOEXIT',
        -verbose  => 99,
        -sections => 'SYNOPSIS|OPTIONS|PARAMETERS',
        -input    => __FILE__,
    );

    return 0;
}

sub man {
    my $self = shift;

    pod2usage(
        -exitval => 'NOEXIT',
        -verbose => 2,
        -input   => __FILE__,
    );

    return 0;
}

sub usage {
    my $self = shift;

    pod2usage(
        -exitval => 'NOEXIT',
        -verbose => 0,
        -input   => __FILE__,
        -output  => \*STDERR,
    );

    return 1;
}

sub version {
    printf "perlgib %s\n", $Perl::Gib::VERSION;

    return 0;
}

sub BUILD {
    my $self = shift;

    try {
        croak('Missing action')
          if ( !scalar keys %{ $self->options } && !$self->action );

        if ( $self->action ) {
            my $role = sprintf "Perl::Gib::App::%s", ucfirst $self->action;
            apply_all_roles( $self, $role );

            $self->action_options;
        }
    }
    catch {
        my $message = ( split / at/ )[0];

        printf {*STDERR} "%s\n", $message if ($message);
        print "\n";

        exit $self->usage();
    };

    return;
}

sub execute {
    my $self = shift;

    my $info =
        $self->config->library_name eq 'Library'
      ? $self->config->library_path
      : $self->config->library_name;

    printf "%s (%s)\n", colored( $self->action_info, 'green' ), $info;
    my $start = Time::HiRes::gettimeofday();

    my $rc = try {
        $self->execute_action();
        return 0;
    }
    catch {
        printf {*STDERR} "%s\n", ( split / at/ )[0];
        return 1;
    };

    my $stop = Time::HiRes::gettimeofday();
    printf "%s in %.2fs\n", colored( 'Finished', $rc ? 'red' : 'green' ),
      $stop - $start;

    return $rc;
}

sub run {
    my $self = shift;

    $self = Perl::Gib::App->new() if ( !Scalar::Util::blessed($self) );

    return help()    if ( $self->options->{'help'} );
    return man()     if ( $self->options->{'man'} );
    return version() if ( $self->options->{'version'} );

    return $self->execute();
}

__PACKAGE__->meta->make_immutable;

1;

## no critic (Documentation)

__END__

=encoding utf8

=head1 NAME

perlgib - Perl's alternative documentation and test manager.

=head1 SYNOPSIS

perlgib --help|-h | --man|-m | --version|-v

perlgib [OPTIONS] doc | test [OPTIONS]

=head1 OPTIONS

=head2 base

=over 8

=item --help|-h

Print short usage help.

=item --man|-m

Print extended usage help.

=item --version|-v

Print version string.

=item --library-path PATH

Directory with documents (Perl modules, Markdown files) to process, default
lib in current working directory.

=item --library-name NAME

Library name.

=back

=head2 doc

Build library documentation.

=over 8

=item --output-path

Documentation output path, default doc in current working directory.

=item --output-format html|markdown|pod|all

Documentation output format, default html.

=item --document-private-items

Document private items.

=item --document-ignored-items

Document ignored items (#[ignore(item)]).

=item --no-html-index

Prevent creating of html index.

=back

=head2 test

Execute documentation tests.

=head1 DESCRIPTION

perlgib is Perl's alternative documentation and test manager.

perlgib generates HTML and Markdown documentation and runs tests from Perl
code comment lines.

=cut
