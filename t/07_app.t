## no critic
use Test::More;

use Try::Tiny;

subtest 'class' => sub {
    use Test::Moose::More;

    my $class = 'Perl::Gib::App';

    use_ok($class);
    is_class_ok($class);
    is_immutable_ok($class);
    check_sugar_ok($class);
    has_method_ok( $class, qw(execute help man run usage version) );
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

subtest 'execute' => sub {
    use Test::Exception;

    use Try::Tiny;

    use Perl::Gib::App;
    use Perl::Gib::Config;

    my $app = Perl::Gib::App->new();
    throws_ok( sub { $app->execute() }, qr/is not a module name/ );
    Perl::Gib::Config->_clear_instance();

    for my $action (qw(doc test)) {
        open my $devnull, ">&STDOUT";
        open STDOUT, '>', File::Spec->devnull();
        $app = Perl::Gib::App->new( action => $action );
        my $rc = try { $app->execute(); return 1; };
        Perl::Gib::Config->_clear_instance();
        open STDOUT, ">&", $devnull;

        is( $rc, 1, 'Execute action ' . $action );
    }

    $app = Perl::Gib::App->new( action => 'foo' );
    throws_ok( sub { $app->execute() }, qr/is not a Moose role/ );
    Perl::Gib::Config->_clear_instance();
};

subtest 'run' => sub {
    use Perl::Gib::App;
    use Perl::Gib::Config;

    my $app = Perl::Gib::App->new();
    throws_ok( sub { $app->run() }, qr/Call with blessed object denied\./ );
    Perl::Gib::Config->_clear_instance();
};

done_testing();
