package Template::Event::Context;

#! @author: Serguei Okladnikov
#! @date 01.10.2012
#! @mailto: oklaspec@mail.ru

use strict;
use warnings;
use base 'Template::Context';


our $VERSION = 0.01;
our $DYNAMIC = 0 unless defined $DYNAMIC;



sub event_output {
   $_[0]->{_event_output};
}

sub event_init {
   die 'event alredy initiated' if $_[0]->{event_init};
   $_[0]->{event_init} = 1;
}

sub event_done {
   my ( $self, $res ) = @_;
   $self->{event_init} = undef;
   my $ev = $self->event_pop();
   $self->{event_top} = $ev;
   if( $ev->{resvar} ) {
      $self->stash->set( $ev->{resvar}, $res );
   }

# TODO: here exeptions not hadled, and not evented

   my $output = $ev->{event}->( $self, \$res );
   $self->{event_top} = undef;
}

sub event_push {
   push @{ $_[0]->{event_stack} }, $_[1];
}

sub event_pop {
   pop @{ $_[0]->{event_stack} };
}

sub event_top {
   $_[0]->{event_top}
      ? $_[0]->{event_top}
      : $_[0]->{event_stack}->[ $#{ $_[0]->{event_stack} } ]
}


1;
