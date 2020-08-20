package Perl::Gib::Template;

##! Render document HTML documentation with given
##! [template](https://metacpan.org/pod/Mojo::Template) file.

use strict;
use warnings;

use Moose;

use English qw(-no_match_vars);
use File::Spec::Functions qw(:ALL);
use Carp qw(croak);
use Mojo::Template;

use Perl::Gib::Module;
use Perl::Gib::Markdown;

### Path to template file. [required]
has 'file' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

### [Perl::Gib](../Gib.html) document ([Module](Module.html),
### [Markdown](Markdown.html)). [required]
has 'content' => (
    is       => 'ro',
    isa      => 'Perl::Gib::Module|Perl::Gib::Markdown',
    required => 1,
);

### Any assets. `[Str|ArrayRef|HashRef]` [optional]
has 'assets' => (
    is      => 'ro',
    isa     => 'Maybe[Str|ArrayRef|HashRef]',
    default => sub { return },
);

### #[ignore(item)]
has 'model' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_model',
);

sub _build_model {
    my $self = shift;

    my $fh;
    my $model = do {
        local $RS = undef;
        ## no critic (InputOutput::RequireBriefOpen)
        open $fh, '<', $self->file
          or croak( sprintf "%s: %s", $OS_ERROR, $self->file );
        <$fh>;

    };
    close $fh or undef;

    $model =~ s/^\s+|\s+$//g;

    return $model;
}

### Render content and return HTML documentation.
###
### Following named variables pass data to the template.
###
### **title** - dependent on document type,
### **content** - document HTML documentation,
### **assets** - any data.
###
### ```
###     use Perl::Gib::Module;
###
###     my $module   = Perl::Gib::Module->new( file => 'lib/Perl/Gib/Module.pm' );
###     my $template = Perl::Gib::Template->new(
###         file   => 'lib/Perl/Gib/resources/templates/gib.html.ep',
###         assets => {
###             path => 'lib/Perl/Gib/resources/assets',
###         },
###         content => $module,
###     );
###     my $html  = $template->render();
###     my @lines = split /\n/, $html;
###     is( $lines[0], '<!doctype html>', 'HTML documentation' );
### ```
sub render {
    my $self = shift;

    my ( $source, $title );
    if ( $self->content->isa("Perl::Gib::Markdown") ) {
        my ( $vol, $dir, $file ) = splitpath( $self->content->file );
        $file =~ s/\.md//g;
        $title = $file;
    }
    else {
        $title  = $self->content->package->statement;
        $source = $self->content->code();
    }

    return Mojo::Template->new()->vars(1)->render(
        $self->model,
        {
            title   => $title,
            content => $self->content->to_html,
            assets  => $self->assets,
            source  => $source,
        }
    );
}

### Write rendered content to `$file`.
sub write {
    my ( $self, $file ) = @_;

    my $html = $self->render();

    open my $fh, '>', $file or croak( sprintf "%s: '%s'", $OS_ERROR, $file );
    print {$fh} $html;
    close $fh or undef;

    return;
}

1;
