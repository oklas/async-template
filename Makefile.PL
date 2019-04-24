use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $preop =
  'pod2markdown ./lib/Async/Template.pm ./README.md'
;

WriteMakefile(
    NAME              => 'Async::Template',
    VERSION_FROM      => 'lib/Async/Template.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Async/Template.pm', # retrieve abstract from module
       AUTHOR         => 'Serguei Okladnikov oklaspec@gmail.com') : ()),
    dist => {
      PREOP => $preop,
    },
);
