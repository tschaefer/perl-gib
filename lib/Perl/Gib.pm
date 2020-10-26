package Perl::Gib;

##! Generate Perl project HTML documentation and run module test scripts.
##!
##! Can be used as object
##!
##!     use Perl::Gib;
##!     my $perlgib = Perl::Gib->new();
##!     $perlgib->doc();
##!
##! or subroutines can be called directly.
##!
##!     use Perl::Gib qw(test);
##!     test();

use strict;
use warnings;

use feature qw(state);

use Moose;
Moose::Exporter->setup_import_methods( as_is => [ 'doc', 'test', 'markdown' ],
);

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

our $VERSION = '0.06';

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

### #[ignore(item)]
has 'libpath' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_libpath',
    writer  => '_set_libpath',
);

### #[ignore(item)]
has 'docpath' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_docpath',
    writer  => '_set_docpath',
);

sub _build_docpath {
    my $self = shift;

    return catdir( cwd(), 'doc' );
}

sub _build_libpath {
    my $self = shift;

    my $path = catdir( ( cwd(), 'lib' ) );

    return $path;
}

sub _build_modules {
    my $self = shift;

    my @files;
    find( sub { push @files, $File::Find::name if ( -f and /\.pm$/ ); },
        $self->libpath );

    my @modules;
    foreach my $file (@files) {
        my $module = try { Perl::Gib::Module->new( file => $file ) };
        next if ( !$module );
        push @modules, $module;
    }

    return \@modules;
}

sub _build_markdowns {
    my $self = shift;

    my @files;
    find( sub { push @files, $File::Find::name if ( -f and /\.md$/ ); },
        $self->libpath );

    my @documents =
      map { Perl::Gib::Markdown->new( file => $_ ) } @files;

    return \@documents;
}

sub _resource {
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
        'doc:assets'    => catdir( $self->docpath, 'assets' ),
    );

    return $resources{$label};
}

sub _object_doc_path {
    my ( $self, $object ) = @_;

    my $lib = $self->libpath;
    my $doc = $self->docpath;

    my ( $vol, $dir, $file ) = splitpath( $object->file );

    $dir =~ s/$lib//;
    $dir = catdir( $doc, $dir );
    $dir = catpath( $vol, rel2abs($dir) );

    $file =~ s/\.pm|\.md$/\.html/;
    $file = catfile( $dir, $file );
    $file = catpath( $vol, rel2abs($file) );

    return ( $dir, $file );
}

sub _create_doc {
    my ( $self, $object ) = @_;

    my ( $dir, $file ) = $self->_object_doc_path($object);
    make_path($dir);

    my $template = catfile( $self->_resource('lib:templates'), 'gib.html.ep' );
    my $html     = Perl::Gib::Template->new(
        file   => $template,
        assets => {
            path  => abs2rel( $self->_resource('doc:assets'),          $dir ),
            index => abs2rel( catfile( $self->docpath, 'index.html' ), $dir ),
        },
        content => $object
    );

    $html->write($file);

    return;
}

sub _create_index {
    my $self = shift;

    my %index;
    foreach my $module ( @{ $self->modules } ) {
        my ( $dir, $file ) = $self->_object_doc_path($module);
        my $title = $module->package->statement;
        $index{$title} = $file;
    }

    foreach my $document ( @{ $self->markdowns } ) {
        my ( $dir, $file ) = $self->_object_doc_path($document);
        my $title = $file;
        ( undef, undef, $title ) = splitpath($file);
        $title =~ s/\.html//;
        $index{$title} = $file;
    }

    return \%index;
}

sub _write_index_file {
    my ( $self, $index ) = @_;

    my $template = <<'TEMPLATE';
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="description" content="Perl Module Documentation">
    <meta name="author" content="perlgib">
    <title>Perl Module Documentation Index</title>
    <link rel="stylesheet" href="<%= $path %>/css/normalize.css">
    <link rel="stylesheet" href="<%= $path %>/fonts/vollkorn.css">
    <link rel="stylesheet" href="<%= $path %>/css/highlight.css">
    <link rel="stylesheet" href="<%= $path %>/css/gib.css">
  </head>
  <body>
    <div id="content">
      <h1>Table of Content</h1>
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
        $index->{$package} = abs2rel( $index->{$package}, $self->docpath );
    }
    my $html = Mojo::Template->new()->vars(1)->render(
        $template,
        {
            index => $index,
            path  => abs2rel( $self->_resource('doc:assets'), $self->docpath ),
        }
    );

    my $file = catfile( $self->docpath, 'index.html' );
    open my $fh, '>', $file or croak( sprintf "%s: '%s'", $OS_ERROR, $file );
    print {$fh} $html;
    close $fh or undef;

    return;
}

### #[ignore(item)]
sub BUILD {
    my $self = shift;

    my $libpath = rel2abs( realpath( $self->libpath ) );
    croak("Library path not found.") if ( !-d $libpath );
    $self->_set_libpath($libpath);

    my $docpath = rel2abs( realpath( $self->docpath ) );
    $self->_set_docpath($docpath);

    return;
}

### Create docpath directory, copy assets (CSS, JS, fonts), generate HTML
### content and write it to files.
###
### ```
###     use File::Find;
###     use File::Copy::Recursive qw(pathrm);
###
###     my $keep = -d 'doc/';
###
###     my $perlgib = Perl::Gib->new();
###     $perlgib->doc();
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
sub doc {
    my $self = shift;

    $self = __PACKAGE__->new() if ( !$self );

    dircopy( $self->_resource('lib:assets'), $self->_resource('doc:assets') );

    my $index = $self->_create_index();
    $self->_write_index_file($index);

    foreach my $object ( @{ $self->modules }, @{ $self->markdowns } ) {
        $self->_create_doc($object);
    }

    return;
}

### Run project modules test scripts.
sub test {
    my $self = shift;

    $self = __PACKAGE__->new() if ( !$self );

    foreach my $module ( @{ $self->modules } ) {
        $module->run_test( $self->libpath );
    }

    return;
}

### Create docpath directory, generate Markdown content and write it to
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
        my ( $dir, $file ) = $self->_object_doc_path($object);
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
