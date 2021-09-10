package Perl::Gib::Util;

##! #[ignore(item)]
##! Perl::Gib internal utilities.

use strict;
use warnings;

use Carp qw(croak);
use Module::Runtime 0.016 qw(use_package_optimistically);
use Readonly;

use Exporter qw(import);

Readonly::Array our @EXPORT_OK => qw(
  throw_exception
);

Readonly::Hash our %EXPORT_TAGS => ( all => [@EXPORT_OK], );

### Throw given exception class including optional arguments.
sub throw_exception {
    my ($class_name, @args_to_exception) = @_;

    my $class = "Perl::Gib::Exception::$class_name";
    &use_package_optimistically( $class);

    croak($class->new( @args_to_exception ));
}

1;
