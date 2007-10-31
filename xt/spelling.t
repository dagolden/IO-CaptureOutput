use Test::More;

my $min_tps = 0.11;
eval "use Test::Spelling $min_tps";
plan skip_all => "Test::Spelling $min_tps required for testing POD" if $@;
system( "ispell -v" ) and plan skip_all => "No ispell";

set_spell_cmd( "ispell -l" );
add_stopwords( qw(
    MSWin
    CPAN
    DAGOLDEN
    README
    STDERR
    STDOUT
    XS
    co
));

all_pod_files_spelling_ok();
