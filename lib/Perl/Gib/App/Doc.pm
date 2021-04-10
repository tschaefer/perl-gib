package Perl::Gib::App::Doc;

use strict;
use warnings;

use Moose::Role;

use Getopt::Long qw(:config require_order);
use List::Util qw(any);

has 'format' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_format',
);

has 'info' => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    builder => '_build_info',
);

sub _build_format {
    my $self = shift;

    $self->_add_options();

    my $format = $self->get_option('output_format') || 'html';
    exit $self->usage() if ( !any { $_ eq $format } qw(html markdown pod all) );

    return $format;
}

sub _build_info {
    my $self = shift;

    return 'Documenting';
}

sub _add_options {
    my $self = shift;

    my %options;

    GetOptions(
        "output-path=s"          => \$options{'output_path'},
        "output-format=s"        => \$options{'output_format'},
        "document-private-items" => \$options{'document_private_items'},
        "document-ignored-items" => \$options{'document_ignored_items'},
        "no-html-index"          => \$options{'no_html_index'},
    ) or exit $self->usage();

    my $format = $options{'output_format'} || 'html';
    exit $self->usage() if ( !any { $_ eq $format } qw(html markdown pod all) );

    foreach my $key ( keys %options ) {
        delete $options{$key} if ( !$options{$key} );
    }
    $self->set_option(%options);

    return;
}

sub _execute {
    my $self = shift;

    $self->perlgib->html()     if ( $self->format =~ /html|all/ );
    $self->perlgib->markdown() if ( $self->format =~ /markdown|all/ );
    $self->perlgib->pod()      if ( $self->format =~ /pod|all/ );

    return;
}

1;
