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
        'File::Temp' => 0.16,  # many bug fixes
    },
    build_requires => {
        'Test::More' => 0.62,  # newer API
    },
    add_to_cleanup => [ '_Inline' ],
);

$build->create_build_script;
