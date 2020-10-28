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
use English qw(-no_match_vars);
use File::Copy::Recursive qw(dircopy dirmove);
use File::Find qw(find);
use Mojo::Template;
use Path::Tiny;
use Try::Tiny;

use Perl::Gib::Markdown;
use Perl::Gib::Module;
use Perl::Gib::Template;

our $VERSION = '0.09';

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
    default => sub { path('lib')->absolute->stringify; },
    writer  => '_set_library_path',
);

### Output path for documentation.
has 'output_path' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { path('doc')->absolute->stringify; },
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
    default => sub { 'Library' },
);

### Prevent creating html index.
has 'no_html_index' => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { 0 },
);

### #[ignore(item)]
has 'tmp_output_path' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_tmp_output_path',
);

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

sub _build_tmp_output_path {
    my $self = shift;

    return Path::Tiny->tempdir->stringify;
}

sub _get_resource_path {
    my ( $self, $label ) = @_;

    state $determine_lib = sub {
        my $file = path(__FILE__)->absolute->stringify;
        my ($dir) = $file =~ /(.+)\.pm$/;

        return $dir;
    };
    state $lib = &$determine_lib();

    state %resources = (
        'lib:assets'    => path( $lib, 'resources', 'assets' ),
        'lib:templates' => path( $lib, 'resources', 'templates' ),
        'out:assets'    => path( $self->tmp_output_path, 'assets' ),
    );

    return $resources{$label};
}

sub _get_obj_out_path {
    my ( $self, $object ) = @_;

    my $lib = $self->library_path;
    my $out = $self->tmp_output_path;

    my $dir  = path( $object->file )->parent->stringify;
    my $file = path( $object->file )->basename;

    $dir =~ s/$lib//;
    $dir = path( $out, $dir );

    $file =~ s/\.pm|\.md$/\.html/;
    $file = path( $dir, $file );

    return ( $dir, $file );
}

sub _create_html_doc {
    my ( $self, $object ) = @_;

    my ( $dir, $file ) = $self->_get_obj_out_path($object);
    path($dir)->mkpath;

    my $index =
      $self->no_html_index
      ? undef
      : path( $self->tmp_output_path, 'index.html' )->relative($dir)->stringify;

    my $template =
      path( $self->_get_resource_path('lib:templates'), 'gib.html.ep' )
      ->stringify;
    my $html = Perl::Gib::Template->new(
        file   => $template,
        assets => {
            path =>
              path( $self->_get_resource_path('out:assets') )->relative($dir)
              ->stringify,
            index => $index,
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
        my ( $dir, $file ) = $self->_get_obj_out_path($module);
        my $title = $module->package->statement;
        $index{$title} = $file;
    }

    foreach my $document ( @{ $self->markdowns } ) {
        my ( $dir, $file ) = $self->_get_obj_out_path($document);
        my $title = path($file)->basename;
        $title =~ s/\.html//;
        $index{$title} = $file;
    }

    return \%index;
}

sub _write_html_index_file {
    my ( $self, $index ) = @_;

    my $model =
      path( $self->_get_resource_path('lib:templates'), 'gib.index.html.ep' )
      ->slurp;

    foreach my $package ( keys %{$index} ) {
        $index->{$package} =
          path( $index->{$package} )->relative( $self->tmp_output_path )
          ->stringify;
    }
    my $html = Mojo::Template->new()->vars(1)->render(
        $model,
        {
            index => $index,
            path  => path( $self->_get_resource_path('out:assets') )
              ->relative( $self->tmp_output_path )->stringify,
            name => $self->library_name,
        }
    );

    my $file = path( $self->tmp_output_path, 'index.html' )->spew($html);

    return;
}

### #[ignore(item)]
sub BUILD {
    my $self = shift;

    my $library_path =
      path( $self->library_path )->absolute->stringify;
    croak("Library path not found.") if ( !-d $library_path );
    $self->_set_library_path($library_path);

    my $output_path = path( $self->output_path )->absolute->stringify;
    $self->_set_output_path($output_path);

    return;
}

### Create documentation directory, copy assets (CSS, JS, fonts), generate HTML
### content and write it to files.
###
### ```
###     use File::Find;
###     use Path::Tiny;
###
###     my $dir = Path::Tiny->tempdir->stringify;
###
###     my $perlgib = Perl::Gib->new({output_path => $dir});
###     $perlgib->html();
###
###     my @wanted = (
###         path( $dir, "Perl/Gib.html" ),
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
### ```
sub html {
    my $self = shift;

    dircopy(
        $self->_get_resource_path('lib:assets'),
        $self->_get_resource_path('out:assets')
    );

    if ( !$self->no_html_index ) {
        my $index = $self->_create_html_index();
        $self->_write_html_index_file($index);
    }

    foreach my $object ( @{ $self->modules }, @{ $self->markdowns } ) {
        $self->_create_html_doc($object);
    }

    dirmove( $self->tmp_output_path, $self->output_path );

    return;
}

### Run project modules test scripts.
sub test {
    my $self = shift;

    foreach my $module ( @{ $self->modules } ) {
        $module->run_test( $self->library_path );
    }

    return;
}

### Create documentation directory, generate Markdown content and write it to
### files.
### ```
###     use File::Find;
###     use Path::Tiny;
###
###     my $dir = Path::Tiny->tempdir->stringify;
###
###     my $perlgib = Perl::Gib->new({output_path => $dir});
###     $perlgib->markdown();
###
###     my @wanted = (
###         path( $dir, "Perl/Gib.md" ),
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
### ```
sub markdown {
    my $self = shift;

    foreach my $object ( @{ $self->modules }, @{ $self->markdowns } ) {
        my ( $dir, $file ) = $self->_get_obj_out_path($object);
        path($dir)->mkpath;

        $file =~ s/\.html/.md/;
        path($file)->spew( $object->to_markdown() );
    }

    dirmove( $self->tmp_output_path, $self->output_path );

    return;
}

__PACKAGE__->meta->make_immutable;

1;
