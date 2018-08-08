package Async::Template;

#! @file
#! @author: Serguei Okladnikov <oklaspec@gmail.com>
#! @date 28.09.2012

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.02';

use Async::Template::Parser;
use Async::Template::Grammar;
use Async::Template::Context;
use Async::Template::Directive;

use Template;
use Template::Provider;
$Template::Provider::DOCUMENT = 'Async::Template::Document';



sub new {
   my $self = bless {}, shift;

   $Template::Config::CONTEXT = 'Async::Template::Context';
   $Template::Config::FACTORY = 'Async::Template::Directive';
   $Template::Config::DOCUMENT = 'Async::Template::Document';
   $Template::Config::PROVIDER = 'Async::Template::Provider';

# WARN! TODO: incompatible with original tewmplate
# impossible to solve upgrade Template does not
# recompile unchaged modules, incomptible ...
# $output and \$output need to test mem usage
# about 2 commented string of code below
# not good idea try to solve in process:
#      my $oldoutput = $Template::Directive::OUTPUT;
#      $Template::Directive::OUTPUT = $oldoutput;
# so
      $Template::Directive::OUTPUT = '${$out} .= ';

   my $config = $_[0];
   
   $self->{EVENT} = $config->{EVENT};
   if( $config->{BLOCKER} && ! $config->{EVENT} ) {
      die 'EVENT cofig options for '.__PACKAGE__.'->new() must be specified if BLOCKER specified'
   } elsif( ! $config->{BLOCKER} && ! $config->{EVENT} ) {
      require 'AnyEvent.pm';
      $self->{_ourblocker} = 1;
      $self->{BLOCKER} = sub {
          $self->{_blockcv}->recv;
      };
      $self->{EVENT} = sub {
         my $output = shift;
         $self->{_output} = $output;
         $self->{_blockcv}->send;
      };
   }
   $self->{config} = $config;
   $self->{tt} = Template->new({
      %{ $self->{config} },
      PARSER  => Async::Template::Parser->new( %{$config},
          GRAMMAR => Async::Template::Grammar->new( %{$config } ),
          FACTORY => Async::Template::Directive->new( %{$config} ),
      ),
   });
   $self
}

sub process {
   my ($self, $template, $vars, $outstream, @opts) = @_;
   my $options = (@opts == 1) && ref($opts[0]) eq 'HASH'
      ? shift(@opts) : { @opts };
   if( $self->{_ourblocker} ) {
      require 'AnyEvent.pm';
      $self->{_blockcv} = AnyEvent->condvar;
   }
   ( defined $outstream && 'SCALAR' ne ref $outstream  ) &&
      die 'only string ref possible as outstream';
   my $context = $self->{tt}->context();
   $context->event_clear;
   my $outstr = '';
   my $output = defined $outstream && 'SCALAR' eq ref $outstream ?
      $outstream : \$outstr;
   $context->{_event_output} = $output;
   my $cb = $options->{EVENT} || $self->{EVENT};
   my $event = sub {
      my $context = shift;
      $cb->( ${$context->event_output()} );
   };
   $context->event_push( {
      event => $event,
      output => $output,
      resvar => undef,
   } );
#   eval{
      #return $self->{tt}->process( $template, $vars, $outstream );
      $self->{tt}->context()->process( $template, $vars );
#   };
   return $self->{tt}->error($@)
      if $@;
   $self->{BLOCKER}->()
      if( $self->{BLOCKER} );
   $outstream ||= $self->{tt}->{OUTPUT};
   return 1;
}

sub context {
   $_[0]->{tt}->context()
}

sub output {
   $_[0]->context->event_output()
}

sub error {
   my $self = shift;
   $self->{tt}->error( @_ )
}

# This tt impl give not good perforance
# will be removed or rewrited with
sub tt {
   my $cb = pop;
   my $src = pop;
   my $vars = ( 1==@_ && 'HASH' eq ref $_[0] ) ? $_[0] : {@_};
   my ($out,$err,$res);
   my $msg = 'two param or two elements array only for RESULT() or ERROR()';

   my $saveres = sub {
      if( 2 == @_ ) {
         ( $err, $res ) = ($_[0], $_[1]);
      } elsif( 1 == @_ ) {
         ( $err, $res ) = 'ARRAY' eq ref $_[0] ?
            ($_[0][0], $_[0][1]) : ($msg, $_[0]);
      } else {
         ( $err, $res ) = ($msg, \@_);
      };
   };

   $vars->{ERROR} ||= sub { $saveres->(@_); $err };
   $vars->{RESULT} ||= sub { $saveres->(@_); $res };

   my $tt = Async::Template->new( { EVENT => sub {
      $cb->($err,$res,$out);
   } } );
   $src =~ s/(.*)/[%$1%]/s;
   $tt->process( \$src, $vars, \$out );
}

sub import {
   my $package = shift;
   my $caller = caller;
   no strict 'refs';
   if( $_[0] && $_[0] eq 'tt' ) {
     *{$caller.'::tt'} = \&{$package.'::tt'};
   }
}

1;

__END__

=head1 NAME

Async::Template - Async Template Toolkit

=head1 SYNOPSIS

  use Async::Template;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Async::Template, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.


=head1 SEE ALSO

=item L<AnyEvent::Handle>;

=item L<AnyEvent::HTTP>;

=item L<JSON::RPC2::AnyEvent::Client>;

=head1 AUTHOR

Serguei Okladnikov E<lt>oklaspec@gmail.comE<gt>

This "Async::Template" package contains parts of "Template Toolkit" and
uses "Template Toolkit" as dependency. The "Template Toolkit" was written
by Andy Wardley E<lt>abw@wardley.orgE<gt> with the invaluable assistance
and contributions from many other people.
See Template::Manual::Credits for details and repos contributors sections.

=head1 COPYRIGHT AND LICENSE 

Async::Template

Copyright (C) 2012-present Serguei Okladnikov

Template::Toolkit

Copyright (C) 1996-present Andy Wardley.

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
