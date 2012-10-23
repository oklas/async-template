package Template::Event;

#! @author: Serguei Okladnikov
#! @date 28.09.2012
#! @mailto: oklaspec@mail.ru

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.01';

use Template::Event::Parser;
use Template::Event::Grammar;
use Template::Event::Context;
use Template::Event::Directive;




sub new {
   my $self = bless {}, shift;

   $Template::Config::CONTEXT = 'Template::Event::Context';
   $Template::Config::FACTORY = 'Template::Event::Directive';

# WARN! TODO: incompatible with original tewmplate
# impossible to solve upgrade Template does not
# recompile unchaged modules, incomptible ...
# $output and \$output need to test mem usage
# about 2 commented string of code below
# not good idea try to solve in process:
#      my $oldoutput = $Template::Directive::OUTPUT;
#      $Template::Directive::OUTPUT = $oldoutput;
# so
      $Template::Directive::OUTPUT = '${$output} .= ';

   my $config = $_[0];
   
   if( $config->{BLOCKER} && ! $config->{EVENT} ) {
      die 'EVENT cofig options for '.__PACKAGE__.'->new() must be specified if BLOCKER specified'
   } elsif( ! $config->{BLOCKER} && ! $config->{EVENT} ) {
      require 'AnyEvent.pm';
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
      PARSER  => Template::Event::Parser->new( %{$config},
      GRAMMAR => Template::Event::Grammar->new( %{$config } ),
      FACTORY => Template::Event::Directive->new( %{$config} ),
      ),
   });
   $self
}

sub process {
   my ($self, $template, $vars, $outstream, @opts) = @_;
   my $options = (@opts == 1) && ref($opts[0]) eq 'HASH'
      ? shift(@opts) : { @opts };
   $self->{_blockcv} = AnyEvent->condvar;
   my $context = $self->{tt}->context();
   my $output = '';
   $context->{_event_output} = \$output;
   my $cb = $self->{EVENT};
   my $event = sub {
      my $context = shift;
      $cb->( ${$context->event_output()} );
   };
   $context->event_push( {
      event => $event,
      output => \$output,
      resvar => undef,
   } );
   eval{
      #return $self->{tt}->process( $template, $vars, $outstream );
      $self->{tt}->context()->process( $template, $vars );
   };
   return $self->{tt}->error($@)
        if $@;
   $self->{BLOCKER}->()
      if( $self->{BLOCKER} );
   $outstream ||= $self->{tt}->{OUTPUT};
   if( defined $self->{_output} ) {
     my $error;
     return $self->{tt}->error($error)
        if ($error = &Template::_output( $outstream, $context->event_output, $options ) );
     return 1;
   } else {
      die 'not implemented';
   }
}

sub context {
   my $self = shift;
   $self->{tt}->context()
}

sub output {
}

sub error {
   my $self = shift;
   $self->{tt}->error( @_ )
}



1;

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Template::Event - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Template::Event;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Template::Event, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.


=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Serguei Okladnikov, E<lt>oklas@span.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Serguei Okladnikov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
