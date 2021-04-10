package Perl::Gib::App;

use strict;
use warnings;

use Moose;
use Moose::Util qw(apply_all_roles);

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
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_action',
);

has 'options' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_options',
    traits  => ['Hash'],
    handles => {
        set_option     => 'set',
        get_option     => 'get',
        has_no_options => 'is_empty',
        num_options    => 'count',
        delete_option  => 'delete',
        option_pairs   => 'kv',
    },
);

has 'config' => (
    is      => 'ro',
    isa     => 'Perl::Gib::Config',
    lazy    => 1,
    builder => '_build_config',
);

has 'perlgib' => (
    is      => 'ro',
    isa     => 'Perl::Gib',
    lazy    => 1,
    builder => '_build_perlgib',
);

use Data::Printer;

sub _build_action {
    my $self = shift;

    $self->options;

    my $action = $ARGV[0] || '';
    $action =~ s/-/_/g;

    exit $self->usage() if ( !any { $_ eq $action } qw(doc test) );

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
    ) or exit $self->usage();

    foreach my $key ( keys %options ) {
        delete $options{$key} if ( !$options{$key} );
    }
    my $count = keys %options;

    exit $self->usage()
      if ( ( $options{'help'} || $options{'man'} || $options{'version'} )
        && $count > 1 );

    return \%options;
}

sub _build_config {
    my $self = shift;

    return Perl::Gib::Config->initialize( %{ $self->options } );
}

sub _build_perlgib {
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

sub run {
    my $self = shift;

    $self = Perl::Gib::App->new() if ( !Scalar::Util::blessed($self) );

    return help()    if ( $self->options->{'help'} );
    return man()     if ( $self->options->{'man'} );
    return version() if ( $self->options->{'version'} );

    my $role = sprintf "Perl::Gib::App::%s", ucfirst $self->action;
    apply_all_roles( $self, $role );

    my $lib =
        $self->config->library_name eq 'Library'
      ? $self->config->library_path
      : $self->config->library_name;

    printf "%s (%s)\n", colored( $self->info, 'green' ), $lib;
    my $start = Time::HiRes::gettimeofday();

    my $rc = try {
        $self->_execute();
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

__PACKAGE__->meta->make_immutable;

1;
