package Perl::Gib::Markdown;

##! Read Markdown file.

use strict;
use warnings;

use Moose;

use Carp qw(croak carp);
use English qw(-no_match_vars);
use Text::Markdown qw(markdown);

no warnings "uninitialized";

### Path to Markdown file. [required]
has 'file' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
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

    my $fh;
    my $text = do {
        local $RS = undef;
        ## no critic (InputOutput::RequireBriefOpen)
        open $fh, '<', $self->file
          or croak( sprintf "%s: %s", $OS_ERROR, $self->file );
        <$fh>;

    };
    close $fh or carp( sprintf "%s: %s", $OS_ERROR, $self->file );

    $text =~ s/^\s+|\s+$//g;

    return $text;
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

__PACKAGE__->meta->make_immutable;

1;
