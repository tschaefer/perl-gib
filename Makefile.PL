#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'ABSTRACT'   => 'Perl\'s alternative documentation and test manager.',
    'AUTHOR'     => 'Tobias Schaefer <github@blackox.org>',
    'DISTNAME'   => 'Perl-Gib',
    'EXE_FILES'  => ['bin/perlgib'],
    'META_MERGE' => {
        resources => {
            'license'    => 'http://dev.perl.org/licenses',
            'homepage'   => 'https://github.com/tschaefer/perl-gib',
            'repository' => 'https://github.com/tschaefer/perl-gib.git',
        }
    },
    'NAME'      => 'Perl::Gib',
    'PREREQ_PM' => {
        'File::Copy::Recursive' => '0.45',
        'Mojolicious'           => '8.57',
        'Moose'                 => '2.2012',
        'PPI'                   => '1.270',
        'Readonly'              => '2.05',
        'Text::Markdown'        => '1.000031',
        'Try::Tiny'             => '0.30',
    },
    'VERSION_FROM' => 'lib/Perl/Gib.pm',
    'clean'        => { FILES => 'Perl-Glib-*' },
    'dist'         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'perl', ) : () ),
);
