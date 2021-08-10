## no critic
use Test::More;

subtest 'class' => sub {
    use Test::Moose::More;

    my $class = 'Perl::Gib::Item::Package';

    use_ok($class);
    is_class_ok($class);
    is_immutable_ok($class);
    check_sugar_ok($class);
    has_method_ok( $class, qw(_build_statement _build_description) );
    does_ok( $class, 'Perl::Gib::Item' );
};

subtest 'new' => sub {
    use Test::Exception;

    use Perl::Gib::Module;

    throws_ok(
        sub { Perl::Gib::Module->new( { file => 'lib/Perl/Gib/Item.pm' } ) },
        'Perl::Gib::Exception::PackageIsIgnoredByComment',
        'Ignored by comment.'
    );
};


done_testing();
