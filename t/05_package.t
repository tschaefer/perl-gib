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

done_testing();
