## no critic
use Test::More;

use Try::Tiny;

subtest 'class' => sub {
    use Test::Moose::More;
    use Test::Exception;

    my $class = 'Perl::Gib::App';

    use_ok($class);
    is_class_ok($class);
    is_immutable_ok($class);
    check_sugar_ok($class);
    has_method_ok( $class, qw(help man run usage version) );
};

subtest 'help' => sub {
    use File::Spec;

    use Perl::Gib::App;

    my $app = Perl::Gib::App->new();

    open my $devnull, ">&STDOUT";
    open STDOUT, '>', File::Spec->devnull();
    my $rc = $app->help();
    open STDOUT, ">&", $devnull;

    is( $rc, 1, 'Print help' );
};

subtest 'man' => sub {
    use File::Spec;

    use Perl::Gib::App;

    my $app = Perl::Gib::App->new();

    open my $devnull, ">&STDOUT";
    open STDOUT, '>', File::Spec->devnull();
    my $rc = $app->man();
    open STDOUT, ">&", $devnull;

    is( $rc, 1, 'Print manpage' );
};

subtest 'usage' => sub {
    use File::Spec;

    use Perl::Gib::App;

    my $app = Perl::Gib::App->new();

    open my $devnull, ">&STDERR";
    open STDERR, '>', File::Spec->devnull();
    my $rc = $app->usage();
    open STDERR, ">&", $devnull;

    is( $rc, 1, 'Print usage' );
};

subtest 'run' => sub {
    use Test::Exception;

    use Path::Tiny;
    use Try::Tiny;

    use Perl::Gib::App;
    use Perl::Gib::Config;

    my $app = Perl::Gib::App->new();
    throws_ok(
        sub { $app->run(); },
        qr/Can't locate object method ""/,
        'Run throws exception on missing action.'
    );
    Perl::Gib::Config->_clear_instance();
};

done_testing();
