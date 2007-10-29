#!/usr/bin/perl -w
#$Id: capture.t,v 1.3 2004/11/22 19:51:09 simonflack Exp $
use strict;
use Test::More tests => 13;
use IO::CaptureOutput 'capture';

my ($out, $err);
sub _reset { $_ = '' for ($out, $err); 1};

# Basic test
_reset && capture sub {print __PACKAGE__; print STDERR __FILE__}, \$out, \$err;
is($out, __PACKAGE__, 'captured stdout from perl function');
is($err, __FILE__, 'captured stderr from perl function');

# Check we still get return values
_reset;
my @arg = capture sub {print 'Testing'; return (1,2,3)}, \$out, \$err;
ok($out eq 'Testing' && eq_array(\@arg, [1,2,3]),
   'capture() proxies the return values');

# Check that the captured sub is called in the right context
my $context = capture sub {wantarray};
ok(defined $context && ! $context,
   'capture() calls subroutine in scalar context when appropriate');

($context) = capture sub {wantarray};
ok($context, 'capture() calls subroutine in list context when appropriate');

capture sub {$context = wantarray};
ok(! defined($context), 'capture() calls subroutine in void context when appropriate');

# Test external program, see t/capture_exec.t for more
_reset;
capture sub {system($^X, '-V:archname')}, \$out;
like($out, qr/$^O/, 'capture() caught stdout from external command');

# check we still get stdout/stderr if the code dies
eval {
    capture sub {print "."; print STDERR "5..4..3..2..1.."; die "self-terminating"}, \$out,\$err;
};
like($@, qr/^self-terminating at \Q@{[__FILE__]}/, '$@ still available after capture');
ok($out eq '.' && $err eq '5..4..3..2..1..', 'capture() still populates output and error variables if the code dies');

# test fork()
sub forked_output {
    fork or do {
        print "forked";
        print STDERR "Child pid $$";
        exit;
    };
    select undef, undef, undef, 0.2;
}
capture \&forked_output, \$out, \$err;
ok($out eq 'forked' && $err =~ /^Child pid /, 'capture() traps fork() output');

# Test printing via C code
SKIP: {
    eval "require Inline::C";
    skip "Inline::C not available", 3 if $@;
    eval {
        my $c_code = do {local $/; <DATA>};
        Inline->bind('C' => $c_code);
    };
    skip "Inline->bind failed : $@", 3 if $@;
    ok(test_inline_c(), 'Inline->bind succeeded');

    _reset && capture sub { print_stdout("Hello World") }, \$out, \$err;
    is($out, 'Hello World', 'captured stdout from C function');

    _reset && capture sub { print_stderr("Testing stderr") }, \$out, \$err;
    is($err, 'Testing stderr', 'captured stderr from C function');
}

__DATA__
// A basic sub to test that the bind() succeeded
int test_inline_c () { return 42; }

// print to stdout
void print_stdout (char* text) { printf("%s", text); fflush(stdout); }
 
// print to stderr
void print_stderr (char* text) { fprintf(stderr, "%s", text); fflush(stderr); }
