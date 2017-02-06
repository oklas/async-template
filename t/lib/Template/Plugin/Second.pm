package Template::Plugin::Second;


#! @author: Serguei Okladnikov
#! @date 01.10.2012
#! @mailto: oklaspec@mail.ru

use strict;
use warnings;
use base 'Template::Plugin';
use AnyEvent;
use Time::HiRes;

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

sub now {
  scalar Time::HiRes::time();
}

sub start {
   my $cb = pop @_;
   my ( $self, $second, $value ) = @_;
   $value = 'ok' if 2 == scalar @_;

   # notify system with error message if somthing wrong
   if ( $second < 0 ) {
      $cb->( { error => "second($second) is must be positive" } );
      return;
   }

   # start the event with specific on_event handler
   $self->{tm} = AE::timer $second, 0, sub {
      # now we at event handler    

      # notify system that event done with result any data at param
      $cb->( { result => $value } );
   };
}

1;

