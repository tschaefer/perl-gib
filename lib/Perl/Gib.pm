package Perl::Gib;

##! Generate Perl project HTML documentation and run module test scripts.
##!
##!     use Perl::Gib;
##!     my $perlgib = Perl::Gib->new();
##!     $perlgib->doc();

use strict;
use warnings;

use feature qw(state);

use Moose;

use Carp qw(croak carp);
use Cwd qw(cwd realpath);
use English qw(-no_match_vars);
use File::Copy::Recursive qw(dircopy);
use File::Find qw(find);
use File::Path qw(make_path);
use File::Spec::Functions qw(:ALL);
use Mojo::Template;
use Try::Tiny;

use Perl::Gib::Markdown;
use Perl::Gib::Module;
use Perl::Gib::Template;

our $VERSION = '0.07';

no warnings "uninitialized";

### #[ignore(item)]
has 'modules' => (
    is      => 'ro',
    isa     => 'ArrayRef[Perl::Gib::Module]',
    lazy    => 1,
    builder => '_build_modules',
);

### #[ignore(item)]
has 'markdowns' => (
    is      => 'ro',
    isa     => 'ArrayRef[Perl::Gib::Markdown]',
    lazy    => 1,
    builder => '_build_markdowns',
);

### Path to directory with Perl modules and Markdown files.
has 'library_path' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_library_path',
    writer  => '_set_library_path',
);

### Output path for documentation.
has 'output_path' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_output_path',
    writer  => '_set_output_path',
);

### Document private items.
has 'document_private_items' => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { 0 },
);

### Library name.
has 'library_name' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { 'Table of contents' },
);

sub _build_output_path {
    my $self = shift;

    return catdir( cwd(), 'doc' );
}

sub _build_library_path {
    my $self = shift;

    my $path = catdir( ( cwd(), 'lib' ) );

    return $path;
}

sub _build_modules {
    my $self = shift;

    my @files;
    find( sub { push @files, $File::Find::name if ( -f and /\.pm$/ ); },
        $self->library_path );

    my @modules;
    foreach my $file (@files) {
        my $module = try {
            Perl::Gib::Module->new(
                file                   => $file,
                document_private_items => $self->document_private_items
            )
        };
        next if ( !$module );
        push @modules, $module;
    }

    return \@modules;
}

sub _build_markdowns {
    my $self = shift;

    my @files;
    find( sub { push @files, $File::Find::name if ( -f and /\.md$/ ); },
        $self->library_path );

    my @documents =
      map { Perl::Gib::Markdown->new( file => $_ ) } @files;

    return \@documents;
}

sub _get_resource_path {
    my ( $self, $label ) = @_;

    state $determine_lib = sub {
        my ( $vol, $dir, $file ) = splitpath( realpath(__FILE__) );
        $file =~ s/\.pm//;
        $dir = catdir( $dir, $file );
        return catpath( $vol, $dir );
    };
    state $lib = &$determine_lib();

    state %resources = (
        'lib:assets'    => catdir( $lib, 'resources', 'assets' ),
        'lib:templates' => catdir( $lib, 'resources', 'templates' ),
        'out:assets'    => catdir( $self->output_path, 'assets' ),
    );

    return $resources{$label};
}

sub _get_obj_doc_path {
    my ( $self, $object ) = @_;

    my $lib = $self->library_path;
    my $doc = $self->output_path;

    my ( $vol, $dir, $file ) = splitpath( $object->file );

    $dir =~ s/$lib//;
    $dir = catdir( $doc, $dir );
    $dir = catpath( $vol, rel2abs($dir) );

    $file =~ s/\.pm|\.md$/\.html/;
    $file = catfile( $dir, $file );
    $file = catpath( $vol, rel2abs($file) );

    return ( $dir, $file );
}

sub _create_html_doc {
    my ( $self, $object ) = @_;

    my ( $dir, $file ) = $self->_get_obj_doc_path($object);
    make_path($dir);

    my $template =
      catfile( $self->_get_resource_path('lib:templates'), 'gib.html.ep' );
    my $html = Perl::Gib::Template->new(
        file   => $template,
        assets => {
            path  => abs2rel( $self->_get_resource_path('out:assets'), $dir ),
            index =>
              abs2rel( catfile( $self->output_path, 'index.html' ), $dir ),
        },
        content => $object
    );

    $html->write($file);

    return;
}

sub _create_html_index {
    my $self = shift;

    my %index;
    foreach my $module ( @{ $self->modules } ) {
        my ( $dir, $file ) = $self->_get_obj_doc_path($module);
        my $title = $module->package->statement;
        $index{$title} = $file;
    }

    foreach my $document ( @{ $self->markdowns } ) {
        my ( $dir, $file ) = $self->_get_obj_doc_path($document);
        my $title = $file;
        ( undef, undef, $title ) = splitpath($file);
        $title =~ s/\.html//;
        $index{$title} = $file;
    }

    return \%index;
}

sub _write_html_index_file {
    my ( $self, $index ) = @_;

    my $template = <<'TEMPLATE';
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="description" content="Perl Module Documentation">
    <meta name="author" content="perlgib">
    <title><%= $name %></title>
    <link rel="stylesheet" href="<%= $path %>/css/normalize.css">
    <link rel="stylesheet" href="<%= $path %>/fonts/vollkorn.css">
    <link rel="stylesheet" href="<%= $path %>/css/highlight.css">
    <link rel="stylesheet" href="<%= $path %>/css/gib.css">
  </head>
  <body>
    <div id="content">
      <h1><%= $name %></h1>
      <input type="text" id="index-filter" onkeyup="filter_list()" placeholder="Search for document ...">
      <ul id="index-list">
      <% foreach my $package (sort keys %{$index}) { %>
          <li><a href="<%= $index->{$package} %>"><%= $package %></a></li>
      <% } %>
      </ul>
    </div>
    <script src="<%= $path %>/js/highlight.min.js"></script>
    <script src="<%= $path %>/js/gib.js"></script>
  </body>
</html>
TEMPLATE

    foreach my $package ( keys %{$index} ) {
        $index->{$package} =
          abs2rel( $index->{$package}, $self->output_path );
    }
    my $html = Mojo::Template->new()->vars(1)->render(
        $template,
        {
            index => $index,
            path  => abs2rel(
                $self->_get_resource_path('out:assets'),
                $self->output_path
            ),
            name => $self->library_name,
        }
    );

    my $file = catfile( $self->output_path, 'index.html' );
    open my $fh, '>', $file or croak( sprintf "%s: '%s'", $OS_ERROR, $file );
    print {$fh} $html;
    close $fh or undef;

    return;
}

### #[ignore(item)]
sub BUILD {
    my $self = shift;

    my $library_path = rel2abs( realpath( $self->library_path ) );
    croak("Library path not found.") if ( !-d $library_path );
    $self->_set_library_path($library_path);

    my $output_path = rel2abs( realpath( $self->output_path ) );
    $self->_set_output_path($output_path);

    return;
}

### Create documentation directory, copy assets (CSS, JS, fonts), generate HTML
### content and write it to files.
###
### ```
###     use File::Find;
###     use File::Copy::Recursive qw(pathrm);
###
###     my $keep = -d 'doc/';
###
###     my $perlgib = Perl::Gib->new();
###     $perlgib->html();
###
###     my @wanted = (
###         "doc/Perl/Gib.html",
###         "doc/Perl/Gib/Markdown.html",
###         "doc/Perl/Gib/Module.html",
###         "doc/Perl/Gib/Template.html",
###         "doc/Perl/Gib/Usage.html",
###         "doc/index.html",
###     );
###
###     my @docs;
###     find( sub { push @docs, $File::Find::name if ( -f && /\.html$/ ); }, 'doc/' );
###     @docs = sort @docs;
###
###     is_deeply( \@docs, \@wanted, 'all docs generated' );
###
###     pathrm( 'doc', 1 ) or die("Could not clean up.") if ( !$keep );
### ```
###
### The optional `$name` argument is set as topic in the index HTML document.
sub html {
    my $self = shift;

    $self = __PACKAGE__->new() if ( !$self );

    dircopy(
        $self->_get_resource_path('lib:assets'),
        $self->_get_resource_path('out:assets')
    );

    my $index = $self->_create_html_index();
    $self->_write_html_index_file($index);

    foreach my $object ( @{ $self->modules }, @{ $self->markdowns } ) {
        $self->_create_html_doc($object);
    }

    return;
}

### Run project modules test scripts.
sub test {
    my $self = shift;

    $self = __PACKAGE__->new() if ( !$self );

    foreach my $module ( @{ $self->modules } ) {
        $module->run_test( $self->library_path );
    }

    return;
}

### Create documentation directory, generate Markdown content and write it to
### files.
### ```
###     use File::Find;
###     use File::Copy::Recursive qw(pathrm);
###
###     my $keep = -d 'doc/';
###
###     my $perlgib = Perl::Gib->new();
###     $perlgib->markdown();
###
###     my @wanted = (
###         "doc/Perl/Gib.md",
###         "doc/Perl/Gib/Markdown.md",
###         "doc/Perl/Gib/Module.md",
###         "doc/Perl/Gib/Template.md",
###         "doc/Perl/Gib/Usage.md",
###     );
###
###     my @docs;
###     find( sub { push @docs, $File::Find::name if ( -f && /\.md$/ ); }, 'doc/' );
###     @docs = sort @docs;
###
###     is_deeply( \@docs, \@wanted, 'all docs generated' );
###
###     pathrm( 'doc', 1 ) or die("Could not clean up.") if ( !$keep );
### ```
sub markdown {
    my $self = shift;

    $self = __PACKAGE__->new() if ( !$self );

    foreach my $object ( @{ $self->modules }, @{ $self->markdowns } ) {
        my ( $dir, $file ) = $self->_get_obj_doc_path($object);
        make_path($dir);

        $file =~ s/\.html/.md/;
        open my $fh, '>', $file
          or croak( sprintf "%s: '%s'", $OS_ERROR, $file );
        print {$fh} $object->to_markdown();
        close $fh or undef;
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;
