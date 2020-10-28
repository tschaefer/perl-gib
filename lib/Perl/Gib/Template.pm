package Perl::Gib::Template;

##! Render document HTML documentation with given
##! [template](https://metacpan.org/pod/Mojo::Template) file.

use strict;
use warnings;

use Moose;

use English qw(-no_match_vars);
use Carp qw(croak);
use Mojo::Template;
use Path::Tiny;

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

    return path( $self->file )->slurp;
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
###             path  => 'lib/Perl/Gib/resources/assets',
###             index => '../../index.html',
###         },
###         content => $module,
###     );
###     my $html  = $template->render();
###     my @lines = split /\n/, $html;
###     is( $lines[0], '<!doctype html>', 'HTML documentation' );
### ```
sub render {
    my $self = shift;

    my $title;
    if ( $self->content->isa("Perl::Gib::Markdown") ) {
        my $file = path( $self->content->file )->basename;
        $file =~ s/\.md//g;
        $title = $file;
    }
    else {
        $title = $self->content->package->statement;
    }

    return Mojo::Template->new()->vars(1)->render(
        $self->model,
        {
            title   => $title,
            content => $self->content->to_html,
            assets  => $self->assets,
        }
    );
}

### Write rendered content to `$file`.
sub write {
    my ( $self, $file ) = @_;

    my $html = $self->render();
    path($file)->spew($html);

    return;
}

__PACKAGE__->meta->make_immutable;

1;
