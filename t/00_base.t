## no critic
use Test::More;

use Perl::Gib::Module;

my $module = Perl::Gib::Module->new(file => 'lib/Perl/Gib/Module.pm');
isa_ok($module, 'Perl::Gib::Module');
can_ok($module, qw( to_html to_markdown ));

my $markdown = $module->to_markdown();
my @lines = split /\n/, $markdown;
is($lines[0], '# Perl::Gib::Module', 'Markdown documentation');

my $html = $module->to_html();
my @lines = split /\n/, $html;
is($lines[0], '<h1>Perl::Gib::Module</h1>', 'HTML documentation');

done_testing();
