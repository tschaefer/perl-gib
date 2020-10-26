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
    use File::Copy::Recursive qw(pathrm);

    use Perl::Gib;

    my $keep = -d 'doc/';

    my $perlgib = Perl::Gib->new();
    $perlgib->html();

    my @wanted = (
        "doc/Perl/Gib.html",        "doc/Perl/Gib/Markdown.html",
        "doc/Perl/Gib/Module.html", "doc/Perl/Gib/Template.html",
        "doc/Perl/Gib/Usage.html",  "doc/index.html",
    );

    my @docs;
    find( sub { push @docs, $File::Find::name if ( -f && /\.html$/ ); },
        'doc/' );
    @docs = sort @docs;

    is_deeply( \@docs, \@wanted, 'all docs generated' );

    pathrm( 'doc', 1 ) or die "Could not clean up." if ( !$keep );
};

subtest 'markdown' => sub {
    use File::Find;
    use File::Copy::Recursive qw(pathrm);

    use Perl::Gib;

    my $keep = -d 'doc/';

    my $perlgib = Perl::Gib->new();
    $perlgib->markdown();

    my @wanted = (
        "doc/Perl/Gib.md",        "doc/Perl/Gib/Markdown.md",
        "doc/Perl/Gib/Module.md", "doc/Perl/Gib/Template.md",
        "doc/Perl/Gib/Usage.md",
    );

    my @docs;
    find( sub { push @docs, $File::Find::name if ( -f && /\.md$/ ); }, 'doc/' );
    @docs = sort @docs;

    is_deeply( \@docs, \@wanted, 'all docs generated' );

    pathrm( 'doc', 1 ) or die "Could not clean up." if ( !$keep );
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
