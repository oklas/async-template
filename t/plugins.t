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
use Template::Event;
use Template::Constants qw( :debug );
use AnyEvent;
use Cwd qw( abs_path );
$^W = 1;

my $DEBUG = grep(/^--?d(debug)?$/, @ARGV);

$DEBUG = 1;
#$Template::Test::DEBUG = 0;
#$Template::Plugins::DEBUG = 0;

my $dir = abs_path( -d 't' ? 't/test/plugin' : 'test/plugin' );
my $src = abs_path( -d 't' ? 't/test/lib' : 'test/lib' );
unshift(@INC, $dir);

my $w = AE::cv; # stores whether a condition was flagged

my $tt1 = Template::Event->new({      
    EVENT => sub {
       my $res = shift;
       print $res; $w->send
    },
    INCLUDE_PATH => $src,
COMPILE_DIR=>'.',
    DEBUG        => $DEBUG ? DEBUG_PLUGINS : 0,
}) || die Template->error();


my $tt = [
    def => Template->new(),
    tt1 => $tt1,
];


$tt1->process('plugins1');
$w->recv; 

#$tt1->{tt}->template('plugins1')->process('plugins1');
#my $d = $tt1->context()->template('plugins1');
#print $d->process($tt1->context());
#$d->as_perl();

test_expect(\*DATA, $tt, &callsign());

__END__


#------------------------------------------------------------------------
# basic plugin loads
#------------------------------------------------------------------------
-- test --
[% USE Second() -%]
-- expect --


#------------------------------------------------------------------------
# load Foo plugin through custom PLUGIN_BASE
#------------------------------------------------------------------------
-- test --
-- use tt1 --
[% USE s = Second() -%]
[% EVENT s.start( 1 ) %]
-- expect --



