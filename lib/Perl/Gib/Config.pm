package Perl::Gib::Config;

##! [Singleton](https://metacpan.org/pod/MooseX::Singleton) configuration
##! object.
##!
##!     use Perl::Gib;
##!     use Perl::Gib::Config;
##!
##!     Perl::Gib::Config->initialize(output_path => '/var/www/docs');
##!
##!     my $perlgib = Perl::Gib->new();
##!     $perlgib->doc();

use strict;
use warnings;

use Moose;
use MooseX::Types::Path::Tiny qw(AbsPath AbsDir);
use MooseX::Singleton;

use Path::Tiny;

### Path to directory with Perl modules and Markdown files. [optional]
### > Default `lib` in current directory.
has 'library_path' => (
    is      => 'ro',
    isa     => AbsDir,
    coerce  => 1,
    default => sub { path('lib')->absolute->realpath; },
);

### Output path for documentation. [optional]
### > Default `doc` in current directory.
has 'output_path' => (
    is      => 'ro',
    isa     => AbsPath,
    coerce  => 1,
    default => sub { path('doc')->absolute; },
);

### Document private items. [optional]
has 'document_private_items' => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { 0 },
);

### Library name, used as index header. [optional]
### > Default `Library.`
has 'library_name' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { 'Library' },
);

### Prevent creating html index. [optional]
has 'no_html_index' => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { 0 },
);

### Document ignored items. [optional]
has 'document_ignored_items' => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { 0 },
);

### Ignore undocumented items. [optional]
has 'ignore_undocumented_items' => (
    is      => 'ro',
    isa     => 'Bool',
    default => sub { 0 },
);

__PACKAGE__->meta->make_immutable;

1;
