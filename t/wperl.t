use strict;
use IO::File;
use File::Temp 0.16 ();
use File::Spec;
use Test::More;

if ( $^O ne 'MSWin32' ) {
    plan skip_all => "not MSWin32";
}

( my $wperl = $^X ) =~ s/perl\.exe$/wperl.exe/;

if ( ! -x $wperl ) {
    plan skip_all => "no wperl.exe found";
}

#--------------------------------------------------------------------------#
# test scripts
#--------------------------------------------------------------------------#

my @scripts = qw(
    wperl-capture.pl
    wperl-exec.pl
);

plan tests => 2 * @scripts;

#--------------------------------------------------------------------------#
# loop over scripts and pass a filename for output
#--------------------------------------------------------------------------#

for my $pl ( @scripts ) {
    my $pl_path = File::Spec->catfile('t', 'scripts', $pl);

    my $outputname = File::Temp->new();
    $outputname->close; # avoid Win32 locking it read-only

    system($wperl, $pl_path, $outputname);

    is( $?, 0, "'$pl' no error");

    my $result = IO::File->new( $outputname );

    is_deeply( 
        [ <$result> ], 
        ["STDOUT\n", "STDERR\n"], 
        "'$pl' capture correct" 
    );

}

