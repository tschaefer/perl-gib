package Perl::Gib::App;

##! Perl::Gib application. Parse, validate command line options and execute
##! action.
##!
##!     use Perl::Gib::App;
##!
##!     exit Perl::Gib::App->run(action => 'doc');

use strict;
use warnings;

use Moose;

use Moose::Util::TypeConstraints;

use Pod::Usage;

use Perl::Gib;
use Perl::Gib::Config;

no warnings "uninitialized";

### Action to execute, required.
has 'action' => (
    is       => 'ro',
    isa      => enum( [qw(doc test)] ),
);

### Perl::Gib configuration options.
has 'options' => (
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { return {}; },
);

### #[ignore(item)]
### Perl::Gib configuration options, see [Perl::Gib::Config](../Config.html).
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

### Initialze Perl::Gib configuration.
sub _build_config {
    my $self = shift;

    return Perl::Gib::Config->initialize( %{ $self->options } );
}

### Create Perl::Gib object.
sub _build_controller {
    my $self = shift;

    return Perl::Gib->new();
}

### Print help.
###
### ```
###     use File::Spec;
###
###     my $app = Perl::Gib::App->new();
###
###     open my $devnull, ">&STDOUT";
###     open STDOUT, '>', File::Spec->devnull();
###     my $rc = $app->help();
###     open STDOUT, ">&", $devnull;
###
###     is( $rc, 1, 'Print help' );
### ```
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
###
### ```
###     use File::Spec;
###
###     my $app = Perl::Gib::App->new();
###
###     open my $devnull, ">&STDOUT";
###     open STDOUT, '>', File::Spec->devnull();
###     my $rc = $app->man();
###     open STDOUT, ">&", $devnull;
###
###     is( $rc, 1, 'Print manpage' );
### ```
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
###
### ```
###     use File::Spec;
###
###     my $app = Perl::Gib::App->new();
###
###     open my $devnull, ">&STERR";
###     open STDERR, '>', File::Spec->devnull();
###     my $rc = $app->usage();
###     open STDERR, ">&", $devnull;
###
###     is( $rc, 1, 'Print usage' );
### ```
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

### Run Perl::Gib application.
sub run {
    my ( $self, $action ) = @_;

    $self->config();

    $action //= $self->action;
    $self->controller->$action();

    return;
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
