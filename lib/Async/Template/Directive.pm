package Template::Event::Directive;

#! @author: Serguei Okladnikov
#! @date 08.10.2012
#! @mailto: oklaspec@mail.ru

use strict;
use warnings;
use base 'Template::Directive';


our $VERSION = 0.01;
our $DYNAMIC = 0 unless defined $DYNAMIC;


sub event_proc {
   my ( $self, $block ) = @_;
   return << "EOF";
sub {
   my \$context = shift || die "template sub called without context\\n";
   my \$stash   = \$context->stash;
   my \$output  = \$context->event_output;
   my \$_tt_error;
   eval { BLOCK: {
$block
   } };
   if (\$@) {
      \$_tt_error = \$context->catch(\$@, \\\$output);
      die \$_tt_error unless \$_tt_error->type eq 'return';
   }
   return \$output;
}
EOF
}


#------------------------------------------------------------------------
# template($block)
#------------------------------------------------------------------------

sub template {
   my ($self, $block) = @_;
#   $block = pad($block, 2) if $PRETTY;

   return "sub { return '' }" unless $block =~ /\S/;

   my $res = << "EOF"  ;
$block
EOF

   return $self->event_proc($res);
}


#------------------------------------------------------------------------
# define_event($res,$expr,$block)
#------------------------------------------------------------------------

sub define_event {
   my ( $self, $resvar, $expr, $event ) = @_;
   $resvar = $resvar ? "'$resvar'" : 'undef';
   $event = $self->event_proc( $event );
   return << "END";
   
   # EVENT
   my \$event = $event;
   my \$ev = \$context->event_top();
   \$context->event_push( {
      resvar => $resvar,
      event => \$event,
   } );
   $expr;
   return \$output;
END
}


sub event_finalize {
   return << "END";
   \$context->event_done(\$output);
END
}


#------------------------------------------------------------------------
# event_while($expr, $block, $tail)                    [% WHILE x < 10 %]
#                                                         ...
#                                                      [% END %]
#------------------------------------------------------------------------

sub event_while {
   my ($self, $expr, $block, $tail, $label) = @_;
#   $block = pad($block, 2) if $PRETTY;
   $label ||= 'LOOP';

   my $while_max = $Template::Directive::WHILE_MAX;

   $block = << "EOF";
   if( --\$context->event_top()->{failsafe} && ($expr) ) {
      \$context->event_push( {
	 resvar => undef,
	 event  => \$event,
      } );
$block
   } else {
      die "WHILE loop terminated (> $while_max iterations)\\n"
	 unless \$context->event_top()->{failsafe};
$tail
   }
EOF

   $block = $self->event_proc($block);

   return << "EOF";

   # EVENT $label DECLARE
   my \$event;
   \$event =
$block 
;

   # EVENT $label STARTUP
   \$context->event_top()->{failsafe} = $while_max;
   \$event->( \$context );
   return \$output;
EOF
}

#------------------------------------------------------------------------
# evbent_switch($expr, \@case)                             [% SWITCH %]
#                                                          [% CASE foo %]
#                                                             ...
#                                                          [% END %]
#------------------------------------------------------------------------

sub event_switch {
   my ($self, $expr, $case, $tail) = @_;
   my @case = @$case;
   my ($evented, $calltail,$pct, $match, $block, $default);
   my $caseblock = '';

   $default = pop @case;

   $calltail = <<EOF;
\$context->event_push( {
   event => \$event_tail,
} );
EOF

   foreach $case (@case) {
      $match = $case->[0];
      $block = $case->[1];
      $evented = $case->[2];
#      $block = pad($block, 1) if $PRETTY;

      $pct = $evented ? \$calltail : \'';

      $caseblock .= <<EOF;
\$_tt_match = $match;
\$_tt_match = [ \$_tt_match ] unless ref \$_tt_match eq 'ARRAY';
if (grep(/^\\Q\$_tt_result\\E\$/, \@\$_tt_match)) {
${$pct} $block 
   last EVENTSWITCH;
}
EOF

   } # foreach

   if( defined $default ) {
      if( 'ARRAY' eq ref $default ) {
         #$default = 'my $event = ' . $self->event_proc( $default->[0] ) . ';';
         $default = $default->[0];
      }
      $caseblock .= $calltail . $default
   }
   $tail = 'my $event_tail = ' . $self->event_proc( $tail ) . ';';
#    $caseblock = pad($caseblock, 2) if $PRETTY;

return <<EOF;

# EVENT SWITCH
$tail
do {
   my \$_tt_result = $expr;
   my \$_tt_match;
   EVENTSWITCH: {
$caseblock
   }
};
    
   \$event_tail->( \$context );
EOF
}




1;
