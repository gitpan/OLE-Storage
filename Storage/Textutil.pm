#
# $Id: Textutil.pm,v 0.3.8.1 1997/10/25 01:15:03 schwartz Exp $
#
# *Experimentary* package, handles text format documents. 
#
# Don't use it in its current state! No documentation, therefore!
# 
# It is actually part of Elser, a program to handle word 6 documents, but 
# Elser is not yet ported to perl 5.
#
# Copyright (C) 1996, 1997 Martin Schwartz 
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, you should find it at:
#
#    http://wwwwbs.cs.tu-berlin.de/~schwartz/pmh/COPYING
#
# You can contact me via schwartz@cs.tu-berlin.de
#

package OLE::Storage::Textutil;
use strict;

sub new {
   my ($proto, $Error) = @_;
   my $S = bless ({}, ref($proto) || $proto);
   $S->Error   ($Error) if $Error;
   $S->width   (-1);
   $S->white   ([" "]);
   $S->hyphen  ("-");
   $S->newline ("\n");
   $S->newpar  ("\n");
   $S->pardel  ("\x0d");
   $S->tabdel  ("\x09");
   $S->mode    (0);
   $S;
}
      
sub _error { 
   my $S=shift; 
   defined $S->{ERROR} ? $S->{ERROR}->error(@_) : 0
}

sub width   { my $S=shift; $S->{WIDTH}=shift  if @_; $S->{WIDTH} }
sub white   { my $S=shift; $S->{WHITE}=shift  if @_; $S->{WHITE} }
sub hyphen  { my $S=shift; $S->{HYPHEN}=shift if @_; $S->{HYPHEN} }
sub newline { my $S=shift; $S->{NL}=shift     if @_; $S->{NL} }
sub newpar  { my $S=shift; $S->{NP}=shift     if @_; $S->{NP} }
sub pardel  { my $S=shift; $S->{PDEL}=shift   if @_; $S->{PDEL} }
sub tabdel  { my $S=shift; $S->{TDEL}=shift   if @_; $S->{TDEL} }
sub mode    { my $S=shift; $S->{MODE}=shift   if @_; $S->{MODE} }
sub Error   { my $S=shift; $S->{ERROR}=shift  if @_; $S->{ERROR} }

sub wrap {
#
# 1||0 == wrap(\$buf)
#
# mode  0  Keep a long line, if a word is longer than a line.
#       1  Break a word with a $hyphen, if it is longer than a line.
#
   my ($S, $bufR, $mode) = @_;
   my $par = $S -> pardel();
   my $len;
   my @Tab  = ();
   my @Len  = ();
   for (0 .. split(/$par/, $$bufR, -1)) {
      push (@Len, $len=length($_[$_]));
      push (@Tab, $S->tab_pos(\$_[$_], $len));
      # missing: tab handling
      $S->_column(\$_[$_], $S->width, $len);
   }
   #$S->print_statistic(\@Tab, \@Len);
   $$bufR = join($S->newpar, @_);
1}

sub _column {
#
   my ($S, $bufR, $w, $l) = @_;

   if ($w==1) {
      # Special case: width == 1
      $$bufR = join ($S->newline(), split(//, $$bufR));
      return 1;
   } elsif ($w<0) {
      # Special case: invalid width
      return $S->_error ("Cannot handle negative width.");
   }
   my ($mpos, $mlen, $l1);
   my $pos = 0; 
   while (($pos+$w)<$l) {
      my $status = 0;
      ($mpos, $mlen) = $S->match_white($bufR, $pos, $w);
      if ($mpos < 0) {
         my $sep = $S->mode();
         if ($sep==1) {
            ($mpos, $status) = $S->sep_lite($bufR, $pos, $w);
            $mpos = $l if $mpos > $l;
         } elsif (ref($sep)) {
            # 2do
         } 
         if ((!$sep) || ($mpos<0)) {
            # No line breaks made. Leave overlong lines.
            $pos = $S->next_white($bufR, $pos)-$w+1;
            next;
         }
      }
      $l1 = "";
      if ($status) {
         $l1 .= $S->hyphen() if $status == 1;
         $mlen = 0;
      };
      $l1 .= $S->newline();
      substr($$bufR, $mpos, $mlen) = $l1;
      $l += length($l1) - $mlen;
      $pos = $mpos+length($l1);
   }
1}

sub sep_lite {
#
# 0||1||2 = $S->sep_lite($bufR, $pos, $free)
#
   my ($S, $bufR, $pos, $free) = @_;
   my $mpos = $pos+$free-1;
   if (substr($$bufR, $mpos-1, 1) =~ /[a-zA-ZÄÖÜäöüß]/) {
      return ($mpos, 1);
   } else {
      return ($mpos, 2);
   }
}

sub next_paragraph {
   my ($S, $bufR, $pos) = @_;
   index($$bufR, $S->pardel(), $pos);
}

sub next_tab {
   my ($S, $bufR, $pos) = @_;
   index($$bufR, $S->tabdel(), $pos);
}

sub next_word {
   my ($S, $bufR, $pos) = @_;
   my $end = $S->next_white($bufR, $pos);
   substr($$bufR, $pos, $end-$pos);
}

sub next_white {
#
# $pos = $S -> next_white ($bufR, $pos)
#
   my ($S, $bufR, $pos) = @_;
   my $us = 0; 
   my $os = 0xffffffff;
   for (@{$S->white()}) {
      $us = index($$bufR, $_, $pos);
      next if $us == -1;
      $os = $us if $us < $os;
   }
   $os = length($$bufR) if $os == -1;
   $os;
}

sub match_white {
#
# ($breakpos, $breaklen) = $S -> match_white ($bufR, $pos, $width)
#
   my ($S, $bufR, $pos, $w) = @_;

   my $min = $pos;
   my $max = $min + $w -1;

   my $us;
   my $os = $min;
   for (@{$S->white()}) {
      $us = rindex($$bufR, $_, $max);
      $os = $us if $us > $os;
   }
   return -1 if $os <= $min;

   my ($left, $right, $l, $flag);
   $right = $os;
   $flag=0;
   while (!$flag) {
      $flag = 1;
      for (@{$S->white()}) {
         $l = length($_);
         while (substr($$bufR, $right, $l) =~ /$_/) {
            $right += $l; $flag=0;
         }
      }
   }

   $left=$os;
   $flag=0;
   while (!$flag) {
      $flag = 1;
      for (@{$S->white()}) {
         $l = length($_);
         while (substr($$bufR, $left-$l, $l) =~ /$_/) {
            $left -= $l; $flag=0;
         }
      }
   }

   ($left, $right-$left);
}

##
## --- Tabulators ----------------------------------------------------------
##

sub tab_pos {
   my ($S, $bufR, $l) = @_;

   my $tpos = -1;
   my @tabs = ();

   while( $tpos < $l ) {
      $tpos = $S -> next_tab ($bufR, $tpos+1);
      last if ($tpos > $l);
      last if ($tpos < 0);
      push (@tabs, $tpos);
   }

   \@tabs;
}

sub print_statistic {
   my ($S, $LT, $LL) = @_;
   print "\nTabulator statistic:\n";
   for (0 .. $#$LT) {
      if (defined $LT->[$_]) {
         printf " %03d (%3d): " . "%d " x ($#{$LT->[$_]}+1) . "\n", 
            $_, $LL->[$_], @{$LT->[$_]}
         ;
      } else {
         printf(" %03d (%03d)\n", $_, $LL->[$_]);
      }
   }
   print "\n";
}

"Atomkraft? Nein, danke!";

__END__


1 Tabulator:

   Tab in Position 1: Einrückung gemäß Tabulator 1 in vorhergehender Zeile
		bzw. Anschluß an vorhergehende Zeile

   N (fast) konsekutive Zeilen, Tab mittlere Position, kurze Zeilenlängen: Index

   1 Zeile, Tab linke Position, kurze Zeilenlänge: Überschrift

   1 Zeile, Tab linke Position, lange Zeilenlänge: Eingerückter Absatz

N Tabulator:

   1 Zeile: Tabulatoren nur zur manuellen Korrektor verwandt -> Space.

Gruppen:

   Mehrere 1 Tab Gruppen, dicht beieinander: Gemeinsame Tabulatorposition

