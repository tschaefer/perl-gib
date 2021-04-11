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

    return Perl::Gib::Config->initialize( %{ $self->options } );
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
    );

    return 0;
}

sub man {
    my $self = shift;

    pod2usage( -exitval => 'NOEXIT', -verbose => 2 );

    return 0;
}

sub usage {
    my $self = shift;

    pod2usage( -exitval => 'NOEXIT', -verbose => 0 );

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
