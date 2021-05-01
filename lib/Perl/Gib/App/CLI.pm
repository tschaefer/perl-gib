package Perl::Gib::App::CLI;

##! Perl::Gib command line application. Parse, validate command line options
##! and execute action.
##!
##!     use Perl::Gib::App::CLI;
##!
##!     exit Perl::Gib::App::CLI->run();

use strict;
use warnings;

use Moose;
extends 'Perl::Gib::App';

use Moose::Util qw(ensure_all_roles);

use Carp qw(croak);
use Getopt::Long qw(:config require_order);
use List::Util qw(any);
use Scalar::Util;
use Term::ANSIColor;
use Time::HiRes;
use Try::Tiny;

use Perl::Gib;
use Perl::Gib::Config;

$Term::ANSIColor::AUTORESET = 1;

no warnings "uninitialized";

### #[ignore(item)]
### Action to execute.
has 'action' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    lazy     => 1,
    builder  => '_build_action',
    init_arg => undef,
    required => 0,
);

### #[ignore(item)]
### Perl::Gib configuration options, see [Perl::Gib::Config](../Config.html).
has 'options' => (
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    builder  => '_build_options',
    init_arg => undef,
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
around '_build_config' => sub {
    my ( $orig, $self ) = @_;

    return Perl::Gib::Config->initialize(
        %{ $self->options },
        %{ $self->action_options },
    );
};

### Parse command line arguments, print to stderr on failure.
sub _parse {
    my $self = shift;

    my $rc = try {
        $self->options;
        $self->action;

        return 1;
    }
    catch {
        my $message = ( split / at/ )[0];

        printf {*STDERR} "%s\n", $message if ($message);
        print {*STDERR} "\n";
        $self->usage();

        return 0;
    };

    if ( !scalar keys %{ $self->options } && !$self->action ) {
        print {*STDERR} "Missing action\n";
        $self->usage();

        $rc = 0;
    }

    return $rc;
}

### Setup application. Apply action role and configuration.
sub _setup {
    my $self = shift;

    my $role = sprintf "Perl::Gib::App::CLI::%s", ucfirst $self->action;
    ensure_all_roles( $self, $role );

    my $rc = try {
        $self->config;
    }
    catch {
        my $message = $_->type_constraint_message;

        printf {*STDERR} "%s\n", $message if ($message);
        print {*STDERR} "\n";
        $self->usage();

        return 0;
    };

    return $rc;
}

### Execute action. Print library information and execution time.
sub _execute {
    my $self = shift;

    my $info = $self->config->library_name eq 'Library'
        ? $self->config->library_path
        : $self->config->library_name;

    printf "%s (%s)\n", colored( $self->action_info, 'green' ), $info;
    my $start = Time::HiRes::gettimeofday();

    my $rc = try {
        $self->execute_action();
        return 1;
    }
    catch {
        printf {*STDERR} "%s\n", ( split / at/ )[0];
        return 0;
    };

    my $stop = Time::HiRes::gettimeofday();
    printf "%s in %.2fs\n", colored( 'Finished', $rc ? 'green' : 'red' ),
      $stop - $start;

    return $rc;
}

### Run Perl::Gib command line application.
around 'run' => sub {
    my ( $orig, $self ) = @_;

    croak('Call with blessed object denied.')
      if ( Scalar::Util::blessed($self) );

    $self = Perl::Gib::App::CLI->new();

    return 1 if ( !$self->_parse() );

    $self->help()    && return 0 if ( $self->options->{'help'} );
    $self->man()     && return 0 if ( $self->options->{'man'} );
    $self->version() && return 0 if ( $self->options->{'version'} );

    return 1 if ( !$self->_setup() );

    return !$self->_execute();
};

__PACKAGE__->meta->make_immutable;

1;
