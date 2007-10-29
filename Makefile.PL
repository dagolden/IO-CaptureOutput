# $Id: Makefile.PL,v 1.2 2004/11/21 16:09:29 simonflack Exp $
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'IO::CaptureOutput',
    'VERSION_FROM'	=> 'lib/IO/CaptureOutput.pm',
    'PREREQ_PM'		=> { 'File::Temp' => 0,
                         'Test::More' => 0.45 },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/IO/CaptureOutput.pm',
       AUTHOR     => 'Simon Flack') : ()),
);
