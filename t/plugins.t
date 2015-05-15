#============================================================= -*-perl-*-
#
# t/plugins.t
#
# Test the Template::Plugins module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 1996-2000 Andy Wardley.  All Rights Reserved.
# Copyright (C) 1998-2000 Canon Research Centre Europe Ltd.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
#
#========================================================================

use strict;
use lib qw( t/lib ./lib ../lib ../blib/arch );
use Template::Test;
use Template::Plugins;
use Async::Template;
use Template::Constants qw( :debug );
use Cwd qw( abs_path );
$^W = 1;

my $DEBUG = grep(/^--?d(debug)?$/, @ARGV);

#$DEBUG = 1;
#$Template::Test::DEBUG = 0;
#$Template::Plugins::DEBUG = 0;

my $dir = abs_path( -d 't' ? 't/test/plugin' : 'test/plugin' );
my $src = abs_path( -d 't' ? 't/test/lib' : 'test/lib' );
unshift(@INC, $dir);

my $tt1 = Async::Template->new({
    INCLUDE_PATH => $src,
COMPILE_DIR=>'.',
    DEBUG        => $DEBUG ? DEBUG_PLUGINS : 0,
#    DEBUG => DEBUG_ALL,
}) || die Template->error();


my $tt = [
    def => Template->new(),
    tt1 => $tt1,
];

# cat ~/main/dist/Async-Template/t/usr/home/zYL1WK4y/main/dist/Async-Template/t/test/lib/plugins2
# rm ~/main/dist/Async-Template/t/usr/home/zYL1WK4y/main/dist/Async-Template/t/test/lib/plugins2
# ( cd ~/main/dist/Async-Template/t/ ; perl plugins.t )
# ( cd ~/main/dist/Async-Template/parser/ ; ./yc )^M

=pod
my $out='';
 $tt1->process('plugins2',{},\$out)
 ? print '!'.$out
 : print $tt1->error();
;
 exit;
=cut
=pod
=cut

test_expect(\*DATA, $tt, &callsign());


=pod
# original template is not work, use modern evented (-- use tt1 --)
#------------------------------------------------------------------------
# basic plugin loads
#------------------------------------------------------------------------
-- test --
[%# try original event -%]
original
-- expect --
original
=cut


__END__


#------------------------------------------------------------------------
# load Foo plugin through custom PLUGIN_BASE
#------------------------------------------------------------------------
-- test --
-- use tt1 --
[%# try modern event -%]
[% USE Second(); IF Second; 'modern'; END -%]
-- expect --
modern

-- test --
[%# event call and plugin -%]
[% USE s = Second -%]
[% res = undef -%]
first chunk
[% EVENT res = s.start(-1) -%]
event (negative): [% IF res.error; 'error'; END %]
[% EVENT res = s.start(1) -%]
event (positive): [% res.result %]
-- expect --
first chunk
event (negative): error
event (positive): ok

-- test --
[%# original nested while -%]
[%
   i = 3;
   a = [ '-', 'c', 'b', 'a' ];
   WHILE i;
     j = 3;
     i;
     WHILE j;
       a.$j;
       j = j - 1;
     END;
     "\n";
     i = i - 1;
   END;
   "done";
%]
-- expect --
3abc
2abc
1abc
done

-- test --
[%# evented nested while -%]
[% USE s = Second -%]
[%
   i = 3;
   a = [ '-', 'c', 'b', 'a' ];
   WHILE i;
     j = 3;
     res = undef;
     EVENT res = s.start(0);
     "$i : ${res.result}\n";
     WHILE j;
       '  '; a.$j;
       res = undef;
       EVENT res = s.start(0);
       " : ${res.result}\n";
       j = j - 1;
     END;
     i = i - 1;
   END;
   "done";
%]
-- expect --
3 : ok
  a : ok
  b : ok
  c : ok
2 : ok
  a : ok
  b : ok
  c : ok
1 : ok
  a : ok
  b : ok
  c : ok
done

-- test --
[%# evented switch in while -%]
[%
USE s = Second;
n = 4;
WHILE n;
   SWITCH n;
   CASE '1';     '1';
   CASE DEFAULT; 'd';
   END;

   SWITCH n;
   CASE '1'; 'a';
   CASE '2'; '2'; EVENT res = s.start(0); 'e';
   CASE '3'; '3';
   CASE DEFAULT; 'D'; EVENT res = s.start(0); 'E';
   END;
   "q\n";
   n = n - 1;
END
%]
-- expect -- 
dDEq
d3q
d2eq
1aq

-- test --
[%# evented switch in while -%]
[%
USE s = Second;
list = [ '4', 3, 2, '1' ];
FOREACH n = list;
   SWITCH n;
   CASE '1';     '1';
   CASE DEFAULT; 'd';
   END;

   SWITCH n;
   CASE '1'; 'a';
   CASE '2'; '2'; EVENT res = s.start(0); 'e';
   CASE '3'; '3';
   CASE DEFAULT; 'D'; EVENT res = s.start(0); 'E';
   END;
   "q\n";
END
%]
-- expect -- 
dDEq
d3q
d2eq
1aq

-- test --
[%# evented PROCESS/INCLUDE directives -%]
[%
USE s = Second;
n = 4;
WHILE n;
   SWITCH n;
   CASE '4'; '4'; EVENT res = s.start(0); 'd';
   CASE '3'; '3'; PROCESS evblock; 'c';
   CASE '2'; '2'; PROCESS block; 'b';
   CASE '1'; '1'; PROCESS block + evblock; 'a';
   END;
   n = n - 1;
END;
PROCESS evblock + block;

BLOCK block;
  "B";
END;

BLOCK evblock;
  "E"; EVENT res = s.start(0); 'e';
END;
%]
-- expect --
4d3Eec2Bb1BEeaEeB

-- test --
[%# original capture anon block and edirectives -%]
3[%
NB = BLOCK;
   IF 1; 1; ELSE; 0; END;
%]
[% END %] 2 [% NB %]
-- expect --
3 2 1

-- test --
[%# evented capture anon block and edirectives -%]
3[%
NB = BLOCK;
   USE s = Second;
   EVENT res = s.start(1);
   res.result;
   " ";
   IF 1; 1; ELSE; 0; END;
%]
[% END %] 2 [% NB %]
-- expect --
3 2 ok 1
-- test --
[% # check localization variable for PROCESS/INCLUDE
USE s = Second;
BLOCK test;
   EVENT res = s.start(0);
   var; ':'; 
   var=1;
   EVENT res = s.start(0);
END;
INCLUDE test;       EVENT res = s.start(0); var; " ";
PROCESS test;       EVENT res = s.start(0); var; " ";
INCLUDE test var=2; EVENT res = s.start(0); var; " ";
PROCESS test var=3; EVENT res = s.start(0); var; " ";
%]
-- expect --
: :1 2:1 3:1 
