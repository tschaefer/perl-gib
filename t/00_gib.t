## no critic
use Test::More;

use Try::Tiny;

subtest 'class' => sub {
    use Test::Moose::More;

    my $class = 'Perl::Gib';

    use_ok($class);
    is_class_ok($class);
    is_immutable_ok($class);
    check_sugar_ok($class);
    has_method_ok( $class, qw(html markdown test) );
};

subtest 'html' => sub {
    use File::Find;
    use Path::Tiny;

    my $dir = Path::Tiny->tempdir->stringify;

    my $perlgib = Perl::Gib->new( { output_path => $dir } );
    $perlgib->markdown();

    my @wanted = (
        path( $dir, "Perl/Gib.md" ),
        path( $dir, "Perl/Gib/Markdown.md" ),
        path( $dir, "Perl/Gib/Module.md" ),
        path( $dir, "Perl/Gib/Template.md" ),
        path( $dir, "Perl/Gib/Usage.md" ),
    );

    my @docs;
    find( sub { push @docs, $File::Find::name if ( -f && /\.md$/ ); }, $dir );
    @docs = sort @docs;

    is_deeply( \@docs, \@wanted, 'all docs generated' );
};

subtest 'markdown' => sub {
    use File::Find;
    use Path::Tiny;

    my $dir = Path::Tiny->tempdir->stringify;

    my $perlgib = Perl::Gib->new( { output_path => $dir } );
    $perlgib->markdown();

    my @wanted = (
        path( $dir, "Perl/Gib.md" ),
        path( $dir, "Perl/Gib/Markdown.md" ),
        path( $dir, "Perl/Gib/Module.md" ),
        path( $dir, "Perl/Gib/Template.md" ),
        path( $dir, "Perl/Gib/Usage.md" ),
    );

    my @docs;
    find( sub { push @docs, $File::Find::name if ( -f && /\.md$/ ); }, $dir );
    @docs = sort @docs;

    is_deeply( \@docs, \@wanted, 'all docs generated' );
};

subtest 'test' => sub {
    use File::Spec;

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
