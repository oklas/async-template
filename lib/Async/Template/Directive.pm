package Template::Event::Directive;

#! @author: Serguei Okladnikov
#! @date 08.10.2012
#! @mailto: oklaspec@mail.ru

use strict;
use warnings;
use base 'Template::Directive';


our $VERSION = 0.01;
our $DYNAMIC = 0 unless defined $DYNAMIC;


#------------------------------------------------------------------------
# define_event([$res,$expr],$block)
#------------------------------------------------------------------------

sub define_event {
   my $res = $_[1]->[0];
   my $expr = $_[1]->[1];
   $res = $res ? "'$res'" : 'undef';
   return << "END";
   my \$event =  $_[2];
   my \$ev = \$context->event_back();
   if( ! \$ev->{resvar} ) {
      \$ev->{output} = \$output;
   }
   \$context->event_push( {
      resvar => $res,
      event => \$event,
   } );
   $expr;
END
}

sub event_finalize {
   return << "END";
   \$context->event_done(\$output);
END
}


1;
