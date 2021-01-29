## no critic
use Test::More;

subtest 'class' => sub {
    use Test::Moose::More;

    my $class = 'Perl::Gib::Markdown';

    use_ok($class);
    is_class_ok($class);
    is_immutable_ok($class);
    check_sugar_ok($class);
    has_method_ok( $class, qw(to_markdown to_html to_pod) );
    has_attribute_ok( $class, 'file' );
};

subtest 'new' => sub {
    use Test::Exception;

    use Perl::Gib::Markdown;

    throws_ok(
        sub { Perl::Gib::Markdown->new() },
        'Moose::Exception::AttributeIsRequired',
        'Attribute (file) is required.'
    );

    throws_ok(
        sub { Perl::Gib::Markdown->new( { file => '/not/found.pm' } ) },
        'Moose::Exception::ValidationFailedForInlineTypeConstraint',
        'File not found.'
    );

};

subtest 'documentation' => sub {
    use Perl::Gib::Module;

    my $doc = Perl::Gib::Markdown->new( { file => 'lib/Perl/Gib/Usage.md' } );

    my $markdown = $doc->to_markdown();
    my @lines    = split /\n/, $markdown;
    is( $lines[0], '# perlgib', 'Markdown documentation' );

    my $html  = $doc->to_html();
    my @lines = split /\n/, $html;
    is( $lines[0], '<h1>perlgib</h1>', 'HTML documentation' );

    my $pod   = $doc->to_pod();
    my @lines = split /\n/, $pod;
    is( $lines[0], '=head1 perlgib', 'POD documentation' );
};

done_testing();
