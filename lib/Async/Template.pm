package Template::Event;

#! @author: Serguei Okladnikov
#! @date 28.09.2012
#! @mailto: oklaspec@mail.ru

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.01';

use Template::Event::Grammar;
use Template::Event::Context;
use Template::Parser;
use Template::Event::Directive;




sub new {
   my $self = bless {}, shift;

   $Template::Config::CONTEXT = 'Template::Event::Context';
   $Template::Config::FACTORY = 'Template::Event::Directive';

   my $config = $_[0];
   unless( $config->{EVENT} ) {
      die 'EVENT cofig options for '.__PACKAGE__.'->new() must be specified'
   }
   $self->{EVENT} = $config->{EVENT};
   $self->{tt} = Template->new({
      %{$config},
      GRAMMAR => Template::Event::Grammar->new( %{$config } ),
      FACTORY => Template::Event::Directive->new( %{$config} ),
   });
   $self
}

sub process {
   my $self = shift;
   my $context = $self->{tt}->context();
   my $cb = $self->{EVENT};
   my $event = sub {
      my $context = shift;
      my $output = shift;
      $cb->( $output );
   };
   $context->event_push( {
      resvar => undef,
      event => $event,
      output => '',
   } );
   $context->process( @_ )
   ;
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
