package Perl::Gib;

##! Generate Perl project documentation and run module test scripts.
##!
##!     use Perl::Gib;
##!     my $perlgib = Perl::Gib->new();
##!     $perlgib->doc();

use strict;
use warnings;

use feature qw(state);

use Moose;
use MooseX::Types::Path::Tiny qw(AbsPath AbsDir);

use File::Copy::Recursive qw(dircopy dirmove);
use File::Find qw(find);
use Path::Tiny;
use Try::Tiny;

use Perl::Gib::Config;
use Perl::Gib::Markdown;
use Perl::Gib::Module;
use Perl::Gib::Template;
use Perl::Gib::Index;

our $VERSION = '1.00';

no warnings "uninitialized";

### #[ignore(item)]
### Perl::Gib configuration object.
has 'config' => (
    is       => 'ro',
    isa      => 'Perl::Gib::Config',
    default  => sub { Perl::Gib::Config->instance() },
    init_arg => undef,
);

### #[ignore(item)]
### List of processed Perl modules.
has 'modules' => (
    is       => 'ro',
    isa      => 'ArrayRef[Perl::Gib::Module]',
    lazy     => 1,
    builder  => '_build_modules',
    init_arg => undef,
);

### #[ignore(item)]
### List of processed Markdown files.
has 'markdowns' => (
    is       => 'ro',
    isa      => 'ArrayRef[Perl::Gib::Markdown]',
    lazy     => 1,
    builder  => '_build_markdowns',
    init_arg => undef,
);

### #[ignore(item)]
### Working path (temporary directory) for HTML, Markdown files output.
has 'working_path' => (
    is       => 'ro',
    isa      => AbsPath,
    lazy     => 1,
    builder  => '_build_working_path',
    init_arg => undef,
);

### Find Perl modules in given library path and process them. By default
### modules with pseudo function `#[ignore(item)]` in package comment block
### are ignored.
sub _build_modules {
    my $self = shift;

    my @files;
    find( sub { push @files, $File::Find::name if ( -f and /\.pm$/ ); },
        $self->config->library_path );

    my @modules;
    foreach my $file (@files) {
        my $module = try {
            Perl::Gib::Module->new( file => $file, )
        };
        next if ( !$module );
        push @modules, $module;
    }

    return \@modules;
}

### Find Markdown files in given library path and process them.
sub _build_markdowns {
    my $self = shift;

    my @files;
    find( sub { push @files, $File::Find::name if ( -f and /\.md$/ ); },
        $self->config->library_path );

    my @documents =
      map { Perl::Gib::Markdown->new( file => $_ ) } @files;

    return \@documents;
}

### Create temporary working directory.
sub _build_working_path {
    my $self = shift;

    return Path::Tiny->tempdir;
}

### Get path of resource element by label. If (relative) dir is provided the
### path will be returned relative otherwise absolute.
sub _get_resource_path {
    my ( $self, $label, $relative_dir ) = @_;

    state $determine = sub {
        my $file = path(__FILE__)->absolute->canonpath;
        my ($dir) = $file =~ /(.+)\.pm$/;

        return path( $dir, 'resources' );
    };
    state $path = &$determine();

    state %resources = (
        'lib:assets'           => path( $path, 'assets' ),
        'lib:templates'        => path( $path, 'templates' ),
        'lib:templates:object' => path( $path, 'templates', 'gib.html.ep' ),
        'lib:templates:index'  =>
          path( $path, 'templates', 'gib.index.html.ep' ),
        'out:assets'         => path( $self->working_path, 'assets' ),
        'out:index:html'     => path( $self->working_path, 'index.html' ),
    );
    my $resource = $resources{$label};

    $resource = $resource->relative($relative_dir) if ($relative_dir);

    return $resource->canonpath;
}

### Get absolute output path (directory, file) of Perl::Gib object
### (Perl modules, Markdown files). The type identifies the output file suffix.
###
### * html => `.html`
### * markdown => `.md`
### * pod => `.pod`
sub _get_output_path {
    my ( $self, $object, $type ) = @_;

    my $lib     = $self->config->library_path;
    my $working = $self->working_path;

    my $file = $object->file;
    $file =~ s/$lib/$working/;

    if ( $type eq 'html' ) {
        $file =~ s/\.pm$|\.md$/\.html/;
    }
    elsif ( $type eq 'markdown' ) {
        $file =~ s/\.pm$/\.md/;
    }
    elsif ( $type eq 'pod' ) {
        $file =~ s/\.pm$|\.md$/\.pod/;
    }

    return ( path($file)->parent->canonpath, $file );
}

### Create output directory, copy assets (CSS, JS, fonts), generate HTML
### content and write it to files.
###
### ```
###     use File::Find;
###     use Path::Tiny;
###
###     use Perl::Gib::Config;
###
###     my $dir = Path::Tiny->tempdir;
###
###     Perl::Gib::Config->initialize(output_path => $dir);
###
###     my $perlgib = Perl::Gib->new();
###     $perlgib->html();
###
###     my @wanted = (
###         path( $dir, "Perl/Gib.html" ),
###         path( $dir, "Perl/Gib/App.html" ),
###         path( $dir, "Perl/Gib/App/CLI.html" ),
###         path( $dir, "Perl/Gib/Config.html" ),
###         path( $dir, "Perl/Gib/Markdown.html" ),
###         path( $dir, "Perl/Gib/Module.html" ),
###         path( $dir, "Perl/Gib/Template.html" ),
###         path( $dir, "Perl/Gib/Usage.html" ),
###         path( $dir, "index.html" ),
###     );
###
###     my @docs;
###     find( sub { push @docs, $File::Find::name if ( -f && /\.html$/ ); }, $dir );
###     @docs = sort @docs;
###
###     is_deeply( \@docs, \@wanted, 'all docs generated' );
###
###     $dir->remove_tree( { safe => 0 } );
###
###     Perl::Gib::Config->_clear_instance();
### ```
sub html {
    my $self = shift;

    $self->working_path->mkpath;

    if ( !$self->config->no_html_index ) {

        my $index = Perl::Gib::Index->new(
            modules   => $self->modules,
            markdowns => $self->markdowns,
        );

        my $template = $self->_get_resource_path('lib:templates:index');
        my $html     = Perl::Gib::Template->new(
            file    => $template,
            assets  => 'assets',
            content => $index,
        );

        $html->write( $self->_get_resource_path('out:index:html') );
    }

    foreach my $object ( @{ $self->modules }, @{ $self->markdowns } ) {
        my ( $dir, $file ) = $self->_get_output_path( $object, 'html' );
        path($dir)->mkpath;

        my $template = $self->_get_resource_path('lib:templates:object');
        my $html     = Perl::Gib::Template->new(
            file    => $template,
            assets  => $self->_get_resource_path( 'out:assets', $dir ),
            content => $object
        );

        $html->write($file);
    }

    dircopy(
        $self->_get_resource_path('lib:assets'),
        $self->_get_resource_path('out:assets')
    );
    dirmove( $self->working_path, $self->config->output_path );

    return;
}

### Run project modules test scripts.
sub test {
    my $self = shift;

    foreach my $module ( @{ $self->modules } ) {
        $module->run_test( $self->config->library_path );
    }

    return;
}

### Create output directory, generate Markdown content and write it to files.
### ```
###     use File::Find;
###     use Path::Tiny;
###
###     use Perl::Gib::Config;
###
###     my $dir = Path::Tiny->tempdir;
###
###     Perl::Gib::Config->new(output_path => $dir);
###
###     my $perlgib = Perl::Gib->new();
###     $perlgib->markdown();
###
###     my @wanted = (
###         path( $dir, "Perl/Gib.md" ),
###         path( $dir, "Perl/Gib/App.md" ),
###         path( $dir, "Perl/Gib/App/CLI.md" ),
###         path( $dir, "Perl/Gib/Config.md" ),
###         path( $dir, "Perl/Gib/Markdown.md" ),
###         path( $dir, "Perl/Gib/Module.md" ),
###         path( $dir, "Perl/Gib/Template.md" ),
###         path( $dir, "Perl/Gib/Usage.md" ),
###     );
###
###     my @docs;
###     find( sub { push @docs, $File::Find::name if ( -f && /\.md$/ ); }, $dir );
###     @docs = sort @docs;
###
###     is_deeply( \@docs, \@wanted, 'all docs generated' );
###
###     $dir->remove_tree( { safe => 0 } );
###
###     Perl::Gib::Config->_clear_instance();
### ```
sub markdown {
    my $self = shift;

    $self->working_path->mkpath;

    foreach my $object ( @{ $self->modules }, @{ $self->markdowns } ) {
        my ( $dir, $file ) = $self->_get_output_path( $object, 'markdown' );

        path($dir)->mkpath;
        path($file)->spew( $object->to_markdown() );
    }

    dirmove( $self->working_path, $self->config->output_path );

    return;
}

### Create output directory, generate Pod content and write it to files.
### ```
###     use File::Find;
###     use Path::Tiny;
###
###     use Perl::Gib::Config;
###
###     my $dir = Path::Tiny->tempdir;
###
###     Perl::Gib::Config->new(output_path => $dir);
###
###     my $perlgib = Perl::Gib->new();
###     $perlgib->pod();
###
###     my @wanted = (
###         path( $dir, "Perl/Gib.pod" ),
###         path( $dir, "Perl/Gib/App.pod" ),
###         path( $dir, "Perl/Gib/App/CLI.pod" ),
###         path( $dir, "Perl/Gib/Config.pod" ),
###         path( $dir, "Perl/Gib/Markdown.pod" ),
###         path( $dir, "Perl/Gib/Module.pod" ),
###         path( $dir, "Perl/Gib/Template.pod" ),
###         path( $dir, "Perl/Gib/Usage.pod" ),
###     );
###
###     my @docs;
###     find( sub { push @docs, $File::Find::name if ( -f && /\.pod$/ ); }, $dir );
###     @docs = sort @docs;
###
###     is_deeply( \@docs, \@wanted, 'all docs generated' );
###
###     $dir->remove_tree( { safe => 0 } );
###
###     Perl::Gib::Config->_clear_instance();
### ```
sub pod {
    my $self = shift;

    $self->working_path->mkpath;

    foreach my $object ( @{ $self->modules }, @{ $self->markdowns } ) {
        my ( $dir, $file ) = $self->_get_output_path( $object, 'pod' );

        path($dir)->mkpath;
        path($file)->spew( $object->to_pod() );
    }

    dirmove( $self->working_path, $self->config->output_path );

    return;
}

__PACKAGE__->meta->make_immutable;

1;
