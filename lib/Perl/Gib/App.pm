package Perl::Gib::App;

##! Perl::Gib command line application. Parse, validate command line options
##! and execute action.
##!
##!     use Perl::Gib::App;
##!
##!     exit Perl::Gib::App->run();

use strict;
use warnings;

use Moose;
use Moose::Util qw(ensure_all_roles);

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

no warnings "uninitialized";

### Action to execute.
has 'action' => (
    is      => 'ro',
    isa     => 'Maybe[Str]',
    lazy    => 1,
    builder => '_build_action',
);

### #[ignore(item)]
### Perl::Gib configuration object.
has 'config' => (
    is       => 'ro',
    isa      => 'Perl::Gib::Config',
    lazy     => 1,
    builder  => '_build_config',
    init_arg => undef,
);

### #[ignore(item)]
### Perl::Gib object.
has 'controller' => (
    is       => 'ro',
    isa      => 'Perl::Gib',
    lazy     => 1,
    builder  => '_build_controller',
    init_arg => undef,
);

### Perl::Gib configuration options.
has 'options' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_options',
);

### Parse and validate command line action.
### Croak if action is unknown.
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

### Parse and validate command line options.
### Croak if option is unknown.
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

### Initialze Perl::Gib configuration.
sub _build_config {
    my $self = shift;

    return Perl::Gib::Config->initialize( %{ $self->options },
        %{ $self->action_options } );
}

### Create Perl::Gib object.
sub _build_controller {
    my $self = shift;

    return Perl::Gib->new();
}

### Print help.
sub help {
    my $self = shift;

    pod2usage(
        -exitval  => 'NOEXIT',
        -verbose  => 99,
        -sections => 'SYNOPSIS|OPTIONS|PARAMETERS',
        -input    => __FILE__,
    );

    return 1;
}

### Print manpage.
sub man {
    my $self = shift;

    pod2usage(
        -exitval => 'NOEXIT',
        -verbose => 2,
        -input   => __FILE__,
    );

    return 1;
}

### Print usage.
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

### Print Perl::Gib version.
sub version {
    printf "perlgib %s\n", $Perl::Gib::VERSION;

    return 1;
}

### Execute action.
sub execute {
    my $self = shift;

    my $role = sprintf "Perl::Gib::App::%s", ucfirst $self->action;
    ensure_all_roles( $self, $role );

    $self->execute_action();

    return;
}

### Run Perl::Gib command line application.
### Parse, validate options and apply action role.
sub run {
    my $self = shift;

    croak('Call with blessed object denied.') if ( Scalar::Util::blessed($self) );

    $self = Perl::Gib::App->new();

    try {
        croak('Missing action')
          if ( !scalar keys %{ $self->options } && !$self->action );

        if ( $self->action ) {
            my $role = sprintf "Perl::Gib::App::%s", ucfirst $self->action;
            ensure_all_roles( $self, $role );

            $self->action_options;
        }
    }
    catch {
        my $message = ( split / at/ )[0];

        printf {*STDERR} "%s\n", $message if ($message);
        print {*STDERR} "\n";

        $self->usage() && exit 1;
    };

    help()    && return 0 if ( $self->options->{'help'} );
    man()     && return 0 if ( $self->options->{'man'} );
    version() && return 0 if ( $self->options->{'version'} );

    my $info =
        $self->config->library_name eq 'Library'
      ? $self->config->library_path
      : $self->config->library_name;

    printf "%s (%s)\n", colored( $self->action_info, 'green' ), $info;
    my $start = Time::HiRes::gettimeofday();

    my $rc = try {
        $self->execute();
        return 1;
    }
    catch {
        printf {*STDERR} "%s\n", ( split / at/ )[0];
        return 0;
    };

    my $stop = Time::HiRes::gettimeofday();
    printf "%s in %.2fs\n", colored( 'Finished', $rc ? 'green' : 'red' ),
      $stop - $start;

    return !$rc;
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
