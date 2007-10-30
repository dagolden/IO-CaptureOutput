# $Id: CaptureOutput.pm,v 1.3 2005/03/25 12:44:14 simonflack Exp $
package IO::CaptureOutput;
use strict;
use vars qw/$VERSION @ISA @EXPORT_OK %EXPORT_TAGS/;
use Exporter;
@ISA = 'Exporter';
@EXPORT_OK = qw/capture capture_exec qxx/;
%EXPORT_TAGS = (all => \@EXPORT_OK);
$VERSION = '1.04_01';

sub capture (&@) { ## no critic
    my ($code, $output, $error) = @_;
    for ($output, $error) {
        $_ = \do { my $s; $s = ''} unless ref $_;
        $$_ = '' unless defined($$_);
    }
    my $capture_out = IO::CaptureOutput::_proxy->new('STDOUT', $output);
    my $capture_err = IO::CaptureOutput::_proxy->new('STDERR', $error);
    &$code();
}

sub capture_exec {
    my @args = @_;
    my ($output, $error);
    capture sub { system _shell_quote(@args)}, \$output, \$error;
    return wantarray ? ($output, $error) : $output;
}

*qxx = \&capture_exec;

# extra quoting required on Win32 systems
*_shell_quote = ($^O =~ /MSWin32/) ? \&_shell_quote_win32 : sub {@_};
sub _shell_quote_win32 {
    my @args;
    for (@_) {
        if (/[ \"]/) { # TODO: check if ^ requires escaping
            (my $escaped = $_) =~ s/([\"])/\\$1/g;
            push @args, '"' . $escaped . '"';
            next;
        }
        push @args, $_
    }
    return @args;
}

# Captures everything printed to a filehandle for the lifetime of the object
# and then transfers it to a scalar reference
package IO::CaptureOutput::_proxy;
use File::Temp 'tempfile';
use Symbol qw/gensym qualify qualify_to_ref/;
use Carp;

sub new {
    my $class = shift;
    my ($fh, $capture) = @_;
    $fh       = qualify($fh);         # e.g. main::STDOUT
    my $fhref = qualify_to_ref($fh);  # e.g. \*STDOUT

    # Duplicate the filehandle
    my $saved = gensym;
    open $saved, ">&$fh" or croak "Can't redirect <$fh> - $!";

    # Create replacement filehandle
    my $newio = gensym;
    (undef, my $newio_file) = tempfile;
    open $newio, "+>$newio_file" or croak "Can't create temp file for $fh - $!";

    # Redirect
    open $fhref, ">&".fileno($newio) or croak "Can't redirect $fh - $!";

    bless [$$, $fh, $saved, $capture, $newio, $newio_file], $class;
}

sub DESTROY {
    my $self = shift;

    my ($pid, $fh, $saved) = @{$self}[0..2];
    return unless $pid eq $$; # only cleanup in the process that is capturing

    # restore the original filehandle
    my $fh_ref = Symbol::qualify_to_ref($fh);
    select((select ($fh_ref), $|=1)[0]);
    open $fh_ref, ">&". fileno($saved) or croak "Can't restore $fh - $!";

    # transfer captured data to the scalar reference
    my ($capture, $newio, $newio_file) = @{$self}[3..5];
    seek $newio, 0, 0;
    $$capture = do {local $/; <$newio>};
    close $newio;

    # Cleanup
    return unless -e $newio_file;
    unlink $newio_file or carp "Couldn't remove temp file '$newio_file' - $!";
}

1;

__END__

=pod

=begin wikidoc

= NAME

IO::CaptureOutput - capture STDOUT and STDERR from Perl code, subprocesses or XS

= VERSION

This documentation describes version %%VERSION%%.

= SYNOPSIS

    use IO::CaptureOutput qw(capture capture_exec qxx);

    my ($stdout, $stderr);
    capture sub {noisy(@args)}, \$stdout, \$stderr;
    sub noisy {
        my @args = @_;
        warn "this sub prints to stdout and stderr!";
        ...
        print "finished";
    }

    ($stdout, $stderr) = capture_exec( 'perl', '-e', 
        'print "Hello "; print STDERR "World!"');

= DESCRIPTION

This module provides routines for capturing STDOUT and STDERR from forked
system calls (e.g. {system()}, {fork()}) and from XS/C modules.

= FUNCTIONS

The following functions are be exported on demand.

== {capture(\&subroutine, \$output, \$error)}

Captures everything printed to {STDOUT} and {STDERR} for the duration of
{&subroutine}. {$output} and {$error} are optional scalar references that
will contain {STDOUT} and {STDERR} respectively.

Returns the return value(s) of {&subroutine}. The sub is called in the same
context as {capture()} was called e.g.:

    @rv = capture(sub {wantarray}); # returns true
    $rv = capture(sub {wantarray}); # returns defined, but not true
    capture(sub {wantarray});       # void, returns undef

{capture()} is able to trap output from subprocesses and C code, which
traditional {tie()} methods are unable to capture.

*Note:* {capture()} will only capture output that has been written or flushed
to the filehandle.

== {capture_exec(@args)}

Captures and returns the output from {system(@args)}. In scalar context,
{capture_exec()} will return what was printed to {STDOUT}. In list context,
it returns what was printed to {STDOUT} and {STDERR}

    my $output = capture_exec('perl', '-e', 'print "hello world"');

    my ($output, $error) = capture_exec('perl', '-e', 'warn "Test"');

{capture_exec} passes its arguments to {CORE::system} it can take advantage
of the shell quoting, which makes it a handy and slightly more portable
alternative to backticks, piped {open()} and {IPC::Open3}.

You can check the exit status of the {system()} call with the {$?}
variable. See [perlvar] for more information.

== {qxx(@args)}

This is an alias of {capture_exec}

= SEE ALSO

* [IPC::Open3]
* [IO::Capture]
* [IO::Utils]

= AUTHORS

* Simon Flack <simonflk _AT_ cpan.org> (original author)
* David Golden <dagolden _AT_ cpan.org> (co-maintainer since version 1.04)

= COPYRIGHT AND LICENSE

Portions copyright 2004, 2005 Simon Flack.  Portions copyright 2007 David
Golden.  All rights reserved.

You may distribute under the terms of either the GNU General Public License or
the Artistic License, as specified in the Perl README file.

=end wikidoc 

=cut
