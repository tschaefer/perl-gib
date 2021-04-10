## no critic
use Test::More;

subtest 'class' => sub {
    use Test::Moose::More;

    my $class = 'Perl::Gib::App::CLI';

    use_ok($class);
    is_class_ok($class);
    is_immutable_ok($class);
    check_sugar_ok($class);
};

subtest 'error' => sub {

    my $error_ok = sub {
        my ( $regex, $description ) = @_;

        use File::Temp qw( :seekable );

        use Perl::Gib::App::CLI;
        use Perl::Gib::Config;

        my $fh = File::Temp->new();

        open my $dupstderr, ">&STDERR";
        open STDERR, '>', $fh->filename;
        Perl::Gib::App::CLI->run();
        Perl::Gib::Config->_clear_instance();
        open STDERR, ">&", $dupstderr;

        $fh->seek( 0, SEEK_SET );

        like( <$fh>, $regex, $description );
    };

    $error_ok->( qr/Missing action/, 'Run prints error on missing action.' );

    @ARGV = ('foo');
    $error_ok->( qr/Unknown action/, 'Run prints error on unknown action.' );

    @ARGV = ( '--help', '--man' );
    $error_ok->(
        qr/Too many options/,
        'Run prints error on too many helper options.'
    );

    @ARGV = ('--foo');
    $error_ok->( qr/Unknown option/, 'Run prints error on unknown option.' );

    @ARGV = ( 'doc', '--foo' );
    $error_ok->(
        qr/Unknown option/,
        'Run prints error on unknown action option.'
    );
};

done_testing();
