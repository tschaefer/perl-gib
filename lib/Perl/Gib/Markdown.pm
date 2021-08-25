package Perl::Gib::Markdown;

##! Read Markdown file.

use strict;
use warnings;

use Moose;
use MooseX::Types::Path::Tiny qw(AbsFile);

use Pod::HTML2Pod;
use Text::Markdown qw(markdown);

no warnings "uninitialized";

### Path to Markdown file. [required]
has 'file' => (
    is       => 'ro',
    isa      => AbsFile,
    required => 1,
    coerce   => 1,
);

### #[ignore(item)]
has 'text' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_build_text',
    init_arg => undef,
);

sub _build_text {
    my $self = shift;

    return $self->file->slurp;
}

### #[ignore(item)]
sub BUILD {
    my $self = shift;

    $self->text;

    return;
}

### Return Markdown.
###
### ```
###     my $doc = Perl::Gib::Markdown->new( { file => 'lib/Perl/Gib/Usage.md' } );
###
###     my $markdown = $doc->to_markdown();
###     my @lines    = split /\n/, $markdown;
###     is( $lines[0], '# perlgib', 'Markdown documentation' );
### ```
sub to_markdown {
    my $self = shift;

    return $self->text;
}

### Provide content in HTML.
### ```
###     my $doc = Perl::Gib::Markdown->new( { file => 'lib/Perl/Gib/Usage.md' } );
###
###     my $html  = $doc->to_html();
###     my @lines = split /\n/, $html;
###     is( $lines[0], '<h1>perlgib</h1>', 'HTML documentation' );
### ```
sub to_html {
    my $self = shift;

    return markdown( $self->text );
}

### Provide content in Pod.
### ```
###     my $doc = Perl::Gib::Markdown->new( { file => 'lib/Perl/Gib/Usage.md' } );
###
###     my $pod   = $doc->to_pod();
###     my @lines = split /\n/, $pod;
###     is( $lines[0], '=head1 perlgib', 'Pod documentation' );
### ```
sub to_pod {
    my $self = shift;

    my $html = $self->to_html;

    return Pod::HTML2Pod::convert( content => $html, a_href => 1 );
}

__PACKAGE__->meta->make_immutable;

1;
