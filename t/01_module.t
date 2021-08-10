## no critic
use Test::More;

subtest 'class' => sub {
    use Test::Moose::More;

    my $class = 'Perl::Gib::Module';

    use_ok($class);
    is_class_ok($class);
    is_immutable_ok($class);
    check_sugar_ok($class);
    has_method_ok( $class, qw(to_markdown to_html to_pod run_test) );
    has_attribute_ok( $class, 'file' );
};

subtest 'new' => sub {
    use Test::Exception;

    use Perl::Gib::Module;

    throws_ok(
        sub { Perl::Gib::Module->new() },
        'Moose::Exception::AttributeIsRequired',
        'Attribute (file) is required.'
    );

    throws_ok(
        sub { Perl::Gib::Module->new( { file => '/not/found.pm' } ) },
        'Moose::Exception::ValidationFailedForInlineTypeConstraint',
        'File not found.'
    );

    throws_ok(
        sub { Perl::Gib::Module->new( file => 'lib/Perl/Gib/Usage.md' ) },
        'Perl::Gib::Exception::FileIsNotAPerlModule',
        'Not a Perl module.'
    );
};

subtest 'documentation' => sub {
    use Perl::Gib::Module;

    my $module = Perl::Gib::Module->new( { file => 'lib/Perl/Gib/Module.pm' } );

    my $markdown = $module->to_markdown();
    my @lines    = split /\n/, $markdown;
    is( $lines[0], '# Perl::Gib::Module', 'Markdown documentation' );

    my $html  = $module->to_html();
    my @lines = split /\n/, $html;
    is( $lines[0], '<h1>Perl::Gib::Module</h1>', 'HTML documentation' );

    my $pod   = $module->to_pod();
    my @lines = split /\n/, $pod;
    is( $lines[0], '=head1 Perl::Gib::Module', 'POD documentation' );
};

subtest 'test' => sub {
    use File::Spec;
    use Try::Tiny;

    use Perl::Gib::Module;

    my $module = Perl::Gib::Module->new( { file => 'lib/Perl/Gib/Module.pm' } );
    open my $devnull, ">&STDOUT";
    open STDOUT, '>', File::Spec->devnull();
    my $rc = try {
        $module->run_test('lib');
        return 1;
    }
    catch {
        return 0;
    };
    open STDOUT, ">&", $devnull;

    is( $rc, 1, 'Test run' );
};

done_testing();
