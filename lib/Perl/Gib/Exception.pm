package Perl::Gib::Exception;

##! #[ignore(item)]
##! Perl::Gib base exception class.
##!
##! This class contains attributes which are common to all Perl::Gib internal
##! exception classes.

use strict;
use warnings;

use Moose;
use Devel::StackTrace 2.03;

### Stack trace for the given exception.
has 'trace' => (
    is      => 'ro',
    isa     => 'Devel::StackTrace',
    builder => '_build_trace',
    lazy    => 1,
);

### Exception message.
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

### Create [Devel::StackTrace](https://metacpan.org/pod/Devel::StackTrace)
### object.
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

    return Devel::StackTrace->new(
        message     => $self->message,
        indent      => 1,
        skip_frames => $skip,
        no_refs     => 1,
    );
}

### Every subclass of Perl::Gib is expected to override this  method in order
### to construct this value.
sub _build_message {
    my $self = shift;

    return "Error";
}

sub BUILD {
    my $self = shift;

    return $self->trace;
}

### This method returns a stringified form of the exception, including a stack
### trace. By default, this method skips Perl::Gib-internal stack frames until
### it sees a caller outside of the Perl:Gib core. If the
### `PERL_GIB_FULL_EXCEPTION` environment variable is true, these frames are
### included.
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
