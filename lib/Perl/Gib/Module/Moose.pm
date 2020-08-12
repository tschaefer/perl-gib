package Perl::Gib::Module::Moose;

##! #[ignore(item)]

use strict;
use warnings;

use Moose::Role;

use Readonly;
use Try::Tiny;

use Perl::Gib::Item::Attribute;
use Perl::Gib::Item::Modifier;

Readonly::Hash my %METHOD_MODIFIER_KEYWORDS => (
    after    => 1,
    augment  => 1,
    around   => 1,
    before   => 1,
    override => 1,
);

has 'attributes' => (
    is       => 'ro',
    isa      => 'Maybe[ArrayRef[Perl::Gib::Item::Attribute]]',
    lazy     => 1,
    builder  => '_build_attributes',
    init_arg => undef,
);

has 'modifiers' => (
    is       => 'ro',
    isa      => 'Maybe[ArrayRef[Perl::Gib::Item::Modifier]]',
    lazy     => 1,
    builder  => '_build_modifiers',
    init_arg => undef,
);

sub _build_attributes {
    my $self = shift;

    my @elements = $self->dom->elements();

    my @attributes;
    foreach my $element (@elements) {
        if (   $element->isa('PPI::Statement')
            && $element->first_element eq 'has' )
        {

            # Ignore private attributes.
            # Holy moly this is for pub API documentation,
            # keep your private shit.
            my @subelements = $element->elements();
            next if ( $subelements[1] =~ /^'_/ );

            my @fragment;
            my $previous = $element->previous_sibling();
            while ($previous) {
                if (   $previous->isa('PPI::Token::Comment')
                    && $previous =~ /^###/ )
                {
                    push @fragment, $previous;
                    $previous = $previous->previous_sibling();
                    next;
                }

                push @fragment, $element;
                @fragment = reverse @fragment;

                my $attribute = try {
                    Perl::Gib::Item::Attribute->new( fragment => \@fragment );
                }
                catch {
                    croak($_) if ( $_ !~ /ignored by comment/ );
                };
                last if ( !$attribute );

                push @attributes, $attribute;
                last;
            }
        }
    }

    return \@attributes;
}

sub _build_modifiers {
    my $self = shift;

    my @elements = $self->dom->elements();

    my @modifiers;
    foreach my $element (@elements) {
        if ( $element->isa('PPI::Statement') ) {
            my $keyword = $element->first_element;
            next if ( !$METHOD_MODIFIER_KEYWORDS{$keyword} );

            # Ignore private modifiers.
            # Holy moly this is for pub API documentation,
            # keep your private shit.
            my @subelements = $element->elements();
            next if ( $subelements[1] =~ /^'_/ );

            my @fragment;
            my $previous = $element->previous_sibling();
            while ($previous) {
                if (   $previous->isa('PPI::Token::Comment')
                    && $previous =~ /^###/ )
                {
                    push @fragment, $previous;
                    $previous = $previous->previous_sibling();
                    next;
                }

                push @fragment, $element;
                @fragment = reverse @fragment;

                my $modifier = try {
                    Perl::Gib::Item::Modifier->new( fragment => \@fragment );
                }
                catch {
                    croak($_) if ( $_ !~ /ignored by comment/ );
                };
                last if ( !$modifier );

                push @modifiers, $modifier;
                last;
            }
        }
    }

    return \@modifiers;
}

override 'to_markdown' => sub {
    my $self = shift;

    my $template = <<'TEMPLATE';
# <%= $package->statement %>

% if ($package->description) {
<%= $package->description %>
% }

% if (@{$attributes}) {
## Attributes

% foreach my $attr (@{$attributes}) {
### `<%= $attr->statement %>`

% if ($attr->description) {
<%= $attr->description %>
% }
% else {
> No documentation found.
% }

% }
% }
% if (@{$subroutines}) {
## Methods

% foreach my $sub (@{$subroutines}) {
### `<%= $sub->statement %>`

% if ($sub->description) {
<%= $sub->description %>
% }
% else {
> No documentation found.
% }

% }
% }
% if (@{$modifiers}) {
## Modifiers

% foreach my $mod (@{$modifiers}) {
### `<%= $mod->statement %>`

% if ($mod->description) {
<%= $mod->description %>
% }
% else {
> No documentation found.
% }

% }
% }

TEMPLATE

    return Mojo::Template->new()->vars(1)->render(
        $template,
        {
            package     => $self->package,
            subroutines => $self->subroutines,
            attributes  => $self->attributes,
            modifiers   => $self->modifiers,
        }
    );
};

1;
