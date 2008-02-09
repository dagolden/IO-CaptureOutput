use strict;
use lib 'inc';
use Module::Build::DAGOLDEN;

my $build = Module::Build::DAGOLDEN->new( 
    module_name         => 'IO::CaptureOutput',
    dist_author         => 'David A. Golden <dagolden@cpan.org>',
    license             => 'perl',
    create_readme       => 1,
    create_makefile_pl  => 'traditional',
    requires => {
        'Carp' => 0, 
        'Exporter' => 0, 
        'File::Basename' => 0, 
        'File::Temp' => 0.16,  # many bug fixes
        'Symbol' => 0, 
    },
    build_requires => {
        'File::Spec' => 3.27, # many bug fixes
        'Test::More' => 0.62,  # newer API
        'IO::File' => 0, 
    },
    add_to_cleanup => [ '_Inline' ],
    meta_merge            => { 
        no_index => { 
            directory => [ qw{
                examples
                inc
            }],
        },
        resources => {
            repository => 'http://dagolden.googlecode.com/svn/'
        },
    },
);

$build->create_build_script;

