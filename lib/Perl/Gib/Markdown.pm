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

### Return Markdown.
sub to_markdown {
    my $self = shift;

    return $self->text;
}

### Provide content in HTML.
sub to_html {
    my $self = shift;

    return markdown( $self->text );
}

__PACKAGE__->meta->make_immutable;

1;
