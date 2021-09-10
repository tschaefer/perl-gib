## no critic
use Test::More;

subtest 'class' => sub {
    use Test::Moose::More;

    my $class = 'Perl::Gib';

    use_ok($class);
    is_class_ok($class);
    is_immutable_ok($class);
    check_sugar_ok($class);
    has_method_ok( $class, qw(html markdown pod test) );
};

subtest 'html' => sub {
    use File::Find;
    use Path::Tiny;

    use Perl::Gib::Config;

    my $dir = Path::Tiny->tempdir;

    Perl::Gib::Config->initialize( output_path => $dir );

    my $perlgib = Perl::Gib->new();
    $perlgib->html();

    my @wanted = (
        path( $dir, "Perl/Gib.html" ),
        path( $dir, "Perl/Gib/App.html" ),
        path( $dir, "Perl/Gib/App/CLI.html" ),
        path( $dir, "Perl/Gib/Config.html" ),
        path( $dir, "Perl/Gib/Markdown.html" ),
        path( $dir, "Perl/Gib/Module.html" ),
        path( $dir, "Perl/Gib/Template.html" ),
        path( $dir, "Perl/Gib/Usage.html" ),
        path( $dir, "index.html" ),
    );

    my @docs;
    find( sub { push @docs, $File::Find::name if ( -f && /\.html$/ ); }, $dir );
    @docs = sort @docs;

    is_deeply( \@docs, \@wanted, 'all docs generated' );

    $dir->remove_tree( { safe => 0 } );

    Perl::Gib::Config->_clear_instance();
};

subtest 'html no index' => sub {
    use File::Find;
    use Path::Tiny;

    use Perl::Gib::Config;

    my $dir = Path::Tiny->tempdir;

    Perl::Gib::Config->initialize(
        output_path => $dir,
        no_html_index => 1,
    );

    my $perlgib = Perl::Gib->new();
    $perlgib->html();

    my @wanted = (
        path( $dir, "Perl/Gib.html" ),
        path( $dir, "Perl/Gib/App.html" ),
        path( $dir, "Perl/Gib/App/CLI.html" ),
        path( $dir, "Perl/Gib/Config.html" ),
        path( $dir, "Perl/Gib/Markdown.html" ),
        path( $dir, "Perl/Gib/Module.html" ),
        path( $dir, "Perl/Gib/Template.html" ),
        path( $dir, "Perl/Gib/Usage.html" ),
    );

    my @docs;
    find( sub { push @docs, $File::Find::name if ( -f && /\.html$/ ); }, $dir );
    @docs = sort @docs;

    is_deeply( \@docs, \@wanted, 'all docs generated' );

    $dir->remove_tree( { safe => 0 } );

    Perl::Gib::Config->_clear_instance();
};


subtest 'markdown' => sub {
    use File::Find;
    use Path::Tiny;

    use Perl::Gib::Config;

    my $dir = Path::Tiny->tempdir;

    Perl::Gib::Config->initialize( output_path => $dir );

    my $perlgib = Perl::Gib->new();
    $perlgib->markdown();

    my @wanted = (
        path( $dir, "Perl/Gib.md" ),
        path( $dir, "Perl/Gib/App.md" ),
        path( $dir, "Perl/Gib/App/CLI.md" ),
        path( $dir, "Perl/Gib/Config.md" ),
        path( $dir, "Perl/Gib/Markdown.md" ),
        path( $dir, "Perl/Gib/Module.md" ),
        path( $dir, "Perl/Gib/Template.md" ),
        path( $dir, "Perl/Gib/Usage.md" ),
    );

    my @docs;
    find( sub { push @docs, $File::Find::name if ( -f && /\.md$/ ); }, $dir );
    @docs = sort @docs;

    is_deeply( \@docs, \@wanted, 'all docs generated' );

    $dir->remove_tree( { safe => 0 } );

    Perl::Gib::Config->_clear_instance();
};

subtest 'pod' => sub {
    use File::Find;
    use Path::Tiny;

    use Perl::Gib::Config;

    my $dir = Path::Tiny->tempdir;

    Perl::Gib::Config->initialize( output_path => $dir );

    my $perlgib = Perl::Gib->new();
    $perlgib->pod();

    my @wanted = (
        path( $dir, "Perl/Gib.pod" ),
        path( $dir, "Perl/Gib/App.pod" ),
        path( $dir, "Perl/Gib/App/CLI.pod" ),
        path( $dir, "Perl/Gib/Config.pod" ),
        path( $dir, "Perl/Gib/Markdown.pod" ),
        path( $dir, "Perl/Gib/Module.pod" ),
        path( $dir, "Perl/Gib/Template.pod" ),
        path( $dir, "Perl/Gib/Usage.pod" ),
    );

    my @docs;
    find( sub { push @docs, $File::Find::name if ( -f && /\.pod$/ ); }, $dir );
    @docs = sort @docs;

    is_deeply( \@docs, \@wanted, 'all docs generated' );

    $dir->remove_tree( { safe => 0 } );

    Perl::Gib::Config->_clear_instance();
};

subtest 'test' => sub {
    use File::Spec;
    use Try::Tiny;

    use Perl::Gib;

    my $perlgib = Perl::Gib->new();

    open my $devnull, ">&STDOUT";
    open STDOUT, '>', File::Spec->devnull();
    my $rc = try {
        $perlgib->test();
        return 1;
    }
    catch {
        return 0;
    };
    open STDOUT, ">&", $devnull;

    is( $rc, 1, 'Test run' );
};

done_testing();
