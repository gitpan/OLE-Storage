#
# $Id: Error.pm,v 0.3.8.1 1997/10/25 01:15:01 schwartz Exp $
#
# OLE::Storage::Error, error handling module
#
# Copyright (C) 1997 Martin Schwartz 
#
# Documentation at end of file.
#
# Contact: schwartz@cs.tu-berlin.de
#

package OLE::Storage::Error;
use strict;
my $VERSION=do{my@R=('$Revision: 0.3.8.1 $'=~/\d+/g);sprintf"%d."."%d"x$#R,@R};

sub new {
#
# $ref||undef = Error->new()
#
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $self = {
      STRING => undef,
      NUMBER => undef,
      DESC   => undef
   };
   bless ($self, $class);
}

sub error { 
   my ($S, $str, $num, $long) = @_;
   $str = "unknown error!" if !$str;
   $S->string (caller() . ": $str");
   $S->number ($num)  if $num;
   $S->desc   ($long) if $long;
0}

# -- Member methods ----

sub string {
   my $S = shift;
   if (@_) { $S->{STRING}=shift; 0 } else { $S->{STRING} }
}
sub number {
   my $S = shift;
   if (@_) { $S->{NUMBER}=shift; 0 } else { $S->{NUMBER} }
}
sub desc {
   my $S = shift;
   if (@_) { $S->{DESC}=shift; 0 }   else { $S->{DESC} }
}

"Atomkraft? Nein, danke!"

__END__

=head1 NAME

OLE::Storage::Error - An Error Interface. I<ALPHA> state. 

=head1 SYNOPSIS

use OLE::Storage::Error();

I<$Error>  =  new Error();

0       == I<$Error> -> string ("Error message!");

I<$errstr> =  I<$Error> -> string ();

=head1 DESCRIPTION

OLE::Storage uses this Error object to transmit error messages to
customing programs. 

=head1 SEE ALSO

L<OLE::Storage>

=head1 AUTHOR

Martin Schwartz E<lt>F<schwartz@cs.tu-berlin.de>E<gt>

=cut

