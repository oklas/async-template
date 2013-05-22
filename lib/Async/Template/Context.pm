package Template::Event::Context;

#! @author: Serguei Okladnikov
#! @date 01.10.2012
#! @mailto: oklaspec@mail.ru

use strict;
use warnings;
use base 'Template::Context';
use Scalar::Util 'blessed';


our $VERSION = 0.01;
our $DYNAMIC = 0 unless defined $DYNAMIC;

use constant DOCUMENT => Template::Context::DOCUMENT;


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

# TODO: here exeptions not handled, and not reevented

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
   return $_[0]->{event_stack}->[ $#{ $_[0]->{event_stack} } ];
# ( 16.05.2013 ) TODO: remove any access to 
# $self->{event_top} if no problem appeared later
#   $_[0]->{event_top}
#      ? $_[0]->{event_top}
#      : $_[0]->{event_stack}->[ $#{ $_[0]->{event_stack} } ]
}


#------------------------------------------------------------------------
# process_enter and process_leave event implementation modified from:
#
# process($template, \%params)         [% PROCESS template var=val ... %]
# process($template, \%params, $local) [% INCLUDE template var=val ... %]
#
# Processes the template named or referenced by the first parameter.
# The optional second parameter may reference a hash array of variable
# definitions.  These are set before the template is processed by
# calling update() on the stash.  Note that, unless the third parameter
# is true, the context is not localised and these, and any other
# variables set in the template will retain their new values after this
# method returns.  The third parameter is in place so that this method
# can handle INCLUDE calls: the stash will be localized.
#
# Returns the output of processing the template.  Errors are thrown
# as Template::Exception objects via die().  
#------------------------------------------------------------------------

sub process_enter {
   my ($self, $template, $params, $localize) = @_;
   my $context = $self;
   my ($trim, $blocks) = @$self{ qw( TRIM BLOCKS ) };
   my $compiled;
   my ($stash, $name, $tblocks, $tmpout);
   my $output = '';
    
   my $ev = $self->event_top;

   $ev->{localize} = $localize;
   $ev->{template} = $template;
   $ev->{template} = [ $template ] unless ref $template eq 'ARRAY';

   $self->debug("process([ ", join(', '), @{$ev->{template}}, ' ], ', 
            defined $params ? $params : '<no params>', ', ', 
            $localize ? '<localized>' : '<unlocalized>', ')')
       if $self->{ DEBUG };

   # fetch compiled template for each name specified
   foreach $name (@{$ev->{template}}) {
       push(@{$ev->{compiled}}, $self->template($name));
   }

   if ($localize) {
       # localise the variable stash with any parameters passed
       $stash = $self->{ STASH } = $self->{ STASH }->clone($params);
   } else {
       # update stash with any new parameters passed
       $self->{ STASH }->update($params);
       $stash = $self->{ STASH };
   }

   my $event; $event = sub {
      my $context = shift || die "template sub called without context\n";
      my $stash = $context->stash;
      my $out = $context->event_output;
      my $component;
      my $ev = $self->event_top;

      # save current component
      eval { $component = $stash->get('component') };

      unless( @{$ev->{template}} ) {
          $context->process_leave;
          $context->event_done( $out );
          return '';
      }

      $context->event_push( {
          event => $event,
      } );

      my $name = shift @{$ev->{template}};

      do {
          $compiled = shift @{$ev->{compiled}};
          my $element = ref $compiled eq 'CODE' 
              ? { (name => (ref $name ? '' : $name), modtime => time()) }
              : $compiled;

          if (blessed($component) && $component->isa(DOCUMENT)) {
              $element->{ caller } = $component->{ name };
              $element->{ callers } = $component->{ callers } || [];
              push(@{$element->{ callers }}, $element->{ caller });
          }

          $stash->set('component', $element);
          
          unless ($localize) {
              # merge any local blocks defined in the Template::Document
              # into our local BLOCKS cache
              @$blocks{ keys %$tblocks } = values %$tblocks
                  if (blessed($compiled) && $compiled->isa(DOCUMENT))
                  && ($tblocks = $compiled->blocks);
          }
          
          if (ref $compiled eq 'CODE') {
              $tmpout = &$compiled($self);
          }
          elsif (ref $compiled) {
              $tmpout = $compiled->process($self);
          }
          else {
              $self->throw('file', 
                           "invalid template reference: $compiled");
          }
          
          if ($trim) {
              for ($tmpout) {
                  s/^\s+//;
                  s/\s+$//;
              }
          }
          # $output .= $tmpout;

          # pop last item from callers.  
          # NOTE - this will not be called if template throws an 
          # error.  The whole issue of caller and callers should be 
          # revisited to try and avoid putting this info directly into
          # the component data structure.  Perhaps use a local element
          # instead?

         pop(@{$element->{ callers }})
            if (blessed($component) && $component->isa(DOCUMENT));
      };
      $stash->set('component', $component);
   };

   $event->( $context );
 
}


sub process_leave {
   my $self = shift;
   my ( $error );
   my $ev = $self->event_top;

   $error = $@;
    
   if ($ev->{localize}) {
      # ensure stash is delocalised before dying
      $self->{ STASH } = $self->{ STASH }->declone();
   }
    
   $self->throw(ref $error 
                ? $error : (Template::Constants::ERROR_FILE, $error))
      if $error;
    
   return '';
}


1;
