package Template::Plugin::Second;


#! @author: Serguei Okladnikov
#! @date 01.10.2012
#! @mailto: oklaspec@mail.ru

use strict;
use warnings;
use base 'Template::Plugin';
use AnyEvent;

our $VERSION = 0.01;
our $DYNAMIC = 0 unless defined $DYNAMIC;


sub load {
        my ($class, $context) = @_;
        return $class;
}

sub new {
   my $class = shift;
   my $context = shift;
   bless {
      _CONTEXT => $context,
   }, $class
}

sub start {
   my $self = shift;
   my $second = shift;

   # does not notify system if second is not specified ( for tests )
   return unless defined $second;

   # notify system that this is valid event holder
   $self->{_CONTEXT}->event_init();

   # notify system with error message if somthing wrong
   if ( $second < 0 ) {
      $self->{_CONTEXT}->event_done( { error => "second($second) is must be positive" } );
      return;
   }

   # start the event with specific on_event handler
   $self->{tm} = AE::timer $second, 0, sub {
      # now we at event handler    

      # notify system that event done with result any data at param
      $self->{_CONTEXT}->event_done( { result => 'ok' } );

   };
}

1;

