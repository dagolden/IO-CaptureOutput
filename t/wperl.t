use strict;
use IO::File;
use File::Temp 0.16 ();
use Test::More;

if ( $^O ne 'MSWin32' ) {
    plan skip_all => "not MSWin32";
}

( my $wperl = $^X ) =~ s/perl\.exe$/wperl.exe/;

if ( ! -x $wperl ) {
    plan skip_all => "no wperl.exe found";
}

plan tests => 3;

#--------------------------------------------------------------------------#
# create test script
#--------------------------------------------------------------------------#

my $script = File::Temp->new();
print {$script} <DATA>;
$script->close;

ok( -r "$script", "wrote a capturing program to pass to wperl" );

#--------------------------------------------------------------------------#
# call test script and pass it a filename for writing output
#--------------------------------------------------------------------------#

my $outputname = File::Temp->new();
$outputname->close; # avoid Win32 locking it read-only

system($wperl, $script, $outputname);

is( $?, 0, "wperl executed without error");

my $result = IO::File->new( $outputname );

is_deeply( 
    [ <$result> ], 
    ["STDOUT\n", "STDERR\n"], 
    "correct output captured in wperl" 
);

__DATA__
use strict;
use IO::File;
use IO::CaptureOutput qw/capture/;

my $output_file = shift @ARGV;

my ($stdout, $stderr) = (q{}, q{});
capture sub { 
    print STDOUT "STDOUT\n";
    print STDERR "STDERR\n";
} => \$stdout, \$stderr;

my $fh = IO::File->new($output_file, ">");
print {$fh} $stdout, $stderr;
$fh->close;


