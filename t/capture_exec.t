#!/usr/bin/perl -w
#$Id: capture_exec.t,v 1.3 2004/11/22 19:51:09 simonflack Exp $
use strict;
use Test::More tests => 11;
use IO::CaptureOutput qw/capture_exec capture_exec_combined qxx qxy/;

my ($out, $err);
my @perl_e = ($^X, '-e'); # perl -e

sub _reset { $_ = '' for ($out, $err); 1};

# low-level debugging
#print capture_exec($^X, '-e', 'print join "|", @ARGV'), "\n";
#print join '|', IO::CaptureOutput::_shell_quote($^X, '-e', 'print join "|", @ARGV'), "\n";

# simple test
($out, $err) = capture_exec(@perl_e, q[print 'Hello World!'; print STDERR "PID=$$"]);
is($out, 'Hello World!', 'capture_exec() caught stdout from external command');
like($err, '/PID=\d+/', 'capture_exec() caught stderr from external command');

# with alias
_reset;
($out, $err) = qxx(@perl_e, q[print 'Hello World!'; print STDERR "PID=$$"]);
is($out, 'Hello World!', 'capture_exec() caught stdout from external command');
like($err, '/PID=\d+/', 'capture_exec() caught stderr from external command');

# check exit code of system()
_reset;
($out, $err) = capture_exec(@perl_e, 'print "ok"');
ok($out eq 'ok' && $? == 0, '$? set to 0 after successful execution');

_reset;
($out, $err) = capture_exec(@perl_e, 'print STDERR "not ok"; exit 5');
ok($err eq 'not ok' && $? >> 8 == 5, '$? contains child error after failed execution');

# check that output is returned if called in scalar context
_reset;
$out = capture_exec(@perl_e, 'print "stdout"; print STDERR "stderr"');
is($out, 'stdout', 'capture_exec() returns stdout in scalar context');

# merge STDOUT and STDERR
_reset;
$out = capture_exec_combined(@perl_e, q[select STDERR; $|++; select STDOUT; $|++; print "Hello World!\n"; print STDERR "PID=$$\n"]);
like($out, '/^Hello World!/', 'capture_exec_combined() caught stdout from external command');
like($out, '/PID=\d+$/', 'capture_exec_combined() caught stderr from external command');

# with alias
_reset;
$out = qxy(@perl_e, q[select STDERR; $|++; select STDOUT; $|++; print "Hello World!\n"; print STDERR "PID=$$\n"]);
like($out, '/^Hello World!/', 'capture_exec_combined() caught stdout from external command');
like($out, '/PID=\d+$/', 'capture_exec_combined() caught stderr from external command');

