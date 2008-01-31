use strict;
use Test::More tests => 12;
use IO::CaptureOutput qw/capture/;
use File::Temp qw/tempfile/;
use Config;

my ($out, $err);
sub _reset { $_ = '' for ($out, $err); 1};
sub _readf { 
    return undef unless -r "$_[0]"; 
    local $/; open FF, "< $_[0]"; my $c = <FF>; close FF; 
    return $c 
}

# save output to specified files
(undef, my $saved_out) = tempfile; unlink $saved_out;
(undef, my $saved_err) = tempfile; unlink $saved_err;

_reset && capture sub {print __PACKAGE__; print STDERR __FILE__}, 
    \$out, \$err, $saved_out, $saved_err;
is($out, __PACKAGE__, 'captured stdout from perl function 2');
is($err, __FILE__, 'captured stderr from perl function 2');
ok(-s $saved_out, "saved stdout file contains something");
ok(-s $saved_err, "saved stderr file contains something");
is(_readf($saved_out), __PACKAGE__, 'saved stdout file content ok');
is(_readf($saved_err), __FILE__, 'saved stderr file content ok');

# check that the merged stdout and stderr are saved where they should
unlink $saved_out;
unlink $saved_err;
_reset && capture sub {print __FILE__; print STDERR __PACKAGE__}, 
    \$out, \$out, $saved_out, $saved_err;
like($out, q{/^} . quotemeta(__FILE__) . q{/}, 'captured stdout into one scalar 2');
like($out, q{/} . quotemeta(__PACKAGE__) . q{/}, 'captured stderr into same scalar 2');
ok(-s $saved_out, "saved stdout file contains something");
ok(!-e $saved_err, "saved stderr file does not exist");
like(_readf($saved_out), q{/^} . quotemeta(__FILE__) . q{/}, 'saved merged file stdout content ok');
like(_readf($saved_out), q{/} . quotemeta(__PACKAGE__) . q{/}, 'saved merged file stderr content ok');
unlink $saved_out;
unlink $saved_err;

