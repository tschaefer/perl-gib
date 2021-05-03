## no critic
use Test::More;

subtest 'class' => sub {
    use Test::Moose::More;

    my $class = 'Perl::Gib::App';

    use_ok($class);
    is_class_ok($class);
    is_immutable_ok($class);
    check_sugar_ok($class);
    has_method_ok( $class, qw(help man run usage version) );
};

subtest 'helper' => sub {
    use Perl::Gib::App;

    ok( defined Perl::Gib::App->new()->help(),    "Help returned message." );
    ok( defined Perl::Gib::App->new()->man(),     "Man returned message." );
    ok( defined Perl::Gib::App->new()->usage(),   "Usage returned message." );
    ok( defined Perl::Gib::App->new()->version(), "Version returned message." );

};

subtest 'exceptions' => sub {
    use Test::Exception;

    use Perl::Gib::App;
    use Perl::Gib::Config;

    throws_ok(
        sub {
            Perl::Gib::App->new()->run();
        },
        qr/Can't locate object method ""/,
        'Run throws excpetion on missing action.'
    );
    Perl::Gib::Config->_clear_instance();

    throws_ok(
        sub {
            Perl::Gib::App->new()->run('foo');
        },
        qr/Can't locate object method "foo"/,
        'Run throws excpetion on unknown action.'
    );
    Perl::Gib::Config->_clear_instance();

    throws_ok(
        sub {
            Perl::Gib::App->new( action => 'foo' )->run();
        },
        'Moose::Exception::ValidationFailedForInlineTypeConstraint',
        'App throws excpetion on unknown action attribute.'

    );
    Perl::Gib::Config->_clear_instance();

};

done_testing();
