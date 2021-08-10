package Perl::Gib::Exception;

##! #[ignore(item)]

use strict;
use warnings;

use Moose;
use Devel::StackTrace 2.03;

has 'trace' => (
    is      => 'ro',
    isa     => 'Devel::StackTrace',
    builder => '_build_trace',
    lazy    => 1,
);

has 'message' => (
    is      => 'ro',
    isa     => 'Defined',
    builder => '_build_message',
    lazy    => 1,
);

use overload(
    q{""}    => 'as_string',
    bool     => sub () { 1 },
    fallback => 1,
);

sub _build_trace {
    my $self = shift;

    my $skip = 0;
    while ( my @c = caller( ++$skip ) ) {
        last
          if ( $c[3] =~ /^(.*)::new$/
            || $c[3] =~ /^\S+ (.*)::new \(defined at / )
          && $self->isa($1);
    }
    $skip++;

    Devel::StackTrace->new(
        message     => $self->message,
        indent      => 1,
        skip_frames => $skip,
        no_refs     => 1,
    );
}

sub _build_message {
    my $self = shift;

    return "Error";
}

sub BUILD {
    my $self = shift;

    return $self->trace;
}

sub as_string {
    my $self = shift;

    if ( $ENV{PERL_GIB_FULL_EXCEPTION} ) {
        return $self->trace->as_string;
    }

    my @frames;
    my $last_frame;
    my $in_perl_gib = 1;
    for my $frame ( $self->trace->frames ) {
        if ( $in_perl_gib && $frame->package =~ /^(?:Perl::Gib)(?::|$)/ ) {
            $last_frame = $frame;
            next;
        }
        elsif ($last_frame) {
            push @frames, $last_frame;
            undef $last_frame;
        }

        $in_perl_gib = 0;
        push @frames, $frame;
    }

    return $self->trace->as_string unless @frames;

    my $message = ( shift @frames )->as_string( 1, {} ) . "\n";
    $message .= join q{}, map { $_->as_string( 0, {} ) . "\n" } @frames;

    return $message;
}

__PACKAGE__->meta->make_immutable;

1;
