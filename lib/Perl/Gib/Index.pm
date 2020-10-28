package Perl::Gib::Index;

##! #[ignore(item)]
##! Generate Perl project documentation index, table of contents.

use strict;
use warnings;

use Moose;
use MooseX::Types::Path::Tiny qw(AbsDir);

use Path::Tiny;
use Text::Markdown qw(markdown);

### List of processed Perl modules. [required]
has 'modules' => (
    is      => 'ro',
    isa     => 'ArrayRef[Perl::Gib::Module]',
    required => 1,
);

### List of processed Markdown files. [required]
has 'markdowns' => (
    is      => 'ro',
    isa     => 'ArrayRef[Perl::Gib::Markdown]',
    required => 1,
);

### Path to directory with Perl modules and Markdown files. [required]
has 'library_path' => (
    is       => 'ro',
    isa      => AbsDir,
    required => 1,
    coerce   => 1,
);

### Library name. [required]
has 'library_name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

### Table of contents with topic, link pairs.
has 'toc' => (
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    builder  => '_build_toc',
    init_arg => undef,
);

### Build table of contents.
###
### Iterate through list of objects (Perl modules, Markdown files), gather
### relative object link path and topic.
sub _build_toc {
    my $self = shift;

    my %toc;
    foreach my $object ( @{ $self->modules }, @{ $self->markdowns } ) {
        my $link =
          path( $object->file )->relative( $self->library_path )->canonpath;
        $link =~ s/\.pm$|\.md$/\.html/;

        my $topic = $link;
        $topic =~ s/\.html$//;
        $topic =~ s#/|\\#::#g;

        $toc{$topic} = $link;
    }

    return \%toc;
}

### Provide index in Markdown.
sub to_markdown {
    my $self = shift;

    my $template = <<'TEMPLATE';
# <%= $title %>

<%= $toc %>

TEMPLATE

    my $toc = '';
    foreach my $topic ( sort keys %{ $self->toc } ) {
        $toc .= sprintf "* [%s](%s)\n", $topic, $self->toc->{$topic};
    }

    return Mojo::Template->new()->vars(1)->render(
        $template,
        {
            title => $self->library_name,
            toc   => $toc,
        }
    );
}

### Provide index in HTML.
sub to_html {
    my $self = shift;

    return markdown( $self->to_markdown() );
}

1;
