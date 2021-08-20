package Perl::Gib::App::CLI::Doc;

##! #[ignore(item)]
##! Perl::Gib command line application extension `doc`.

use strict;
use warnings;

use Moose::Role;

use Getopt::Long qw(:config require_order);
use List::Util qw(any);

use Perl::Gib::Util qw(throw_exception);

### Perl::Gib configuration options, see [Perl::Gib::Config](../Config.html).
has 'action_options' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_action_options',
);

### Action information.
has 'action_info' => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'Documenting',
    init_arg => undef,
);

### Parse and validate action command line options.
### Croak if option is unknown.
sub _build_action_options {
    my $self = shift;

    my %options;

    GetOptions(
        "output-path=s"             => \$options{'output_path'},
        "output-format=s"           => \$options{'output_format'},
        "document-private-items"    => \$options{'document_private_items'},
        "document-ignored-items"    => \$options{'document_ignored_items'},
        "ignore-undocumented-items" => \$options{'ignore_undocumented_items'},
        "no-html-index"             => \$options{'no_html_index'},

    ) or throw_exception('AppUnknownOption');

    foreach my $key ( keys %options ) {
        delete $options{$key} if ( !$options{$key} );
    }
    $options{'output_format'} = $options{'output_format'} || 'html';

    throw_exception( 'AppUnknownOutputFormat',
        name => $options{'output_format'} )
      if ( !any { $_ eq $options{'output_format'} } qw(html markdown pod all) );

    return \%options;
}

### Generate documentation in given format, default `html`.
sub execute_action {
    my $self = shift;

    my $format = $self->action_options->{'output_format'} || 'html';

    $self->controller->html()     if ( $format =~ /html|all/ );
    $self->controller->markdown() if ( $format =~ /markdown|all/ );
    $self->controller->pod()      if ( $format =~ /pod|all/ );

    return;
}

1;
