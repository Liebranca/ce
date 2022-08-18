#!/usr/bin/perl
# ---   *   ---   *   ---
# RECT
# Four points, four lines,
# one face to rule them all
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package Rect;

  use v5.36.0;
  use strict;
  use warnings;

  use English qw(-no_match_vars);
  use Carp;

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;

  use Arstd::String;
  use Arstd::IO;

  use parent 'St';

  use lib $ENV{'ARPATH'}.'/lib/';
  use Vec4;
  use Line;

# ---   *   ---   *   ---
# constructor

sub nit(

  # implicit
  $class,

  # actual
  $dim,%O

) {

  # defaults
  $O{pos_x}//=0;
  $O{pos_y}//=0;
  $O{border}//=2;

  my ($sz_x,$sz_y)=split m[x],$dim;

  my %pts=(

    top_l=>Vec4->nit($O{pos_x},$O{pos_y}),
    top_r=>Vec4->nit($O{pos_x}+$sz_x,$O{pos_y}),

    bot_l=>Vec4->nit($O{pos_x},$O{pos_y}+$sz_y),
    bot_r=>Vec4->nit($O{pos_x}+$sz_x,$O{pos_y}+$sz_y),

  );

  # make new instance
  my $rect=bless {

    sz_x=>$sz_x,
    sz_y=>$sz_y,

    pos_x=>$O{pos_x},
    pos_y=>$O{pos_y},
    border=>$O{border},

    top_l=>$pts{top_l},
    top_r=>$pts{top_r},
    bot_l=>$pts{bot_l},
    bot_r=>$pts{bot_r},

    ege_u=>Line->nit(
      $pts{top_l},
      $pts{top_r},

    ),

    ege_l=>Line->nit(
      $pts{top_l},
      $pts{bot_l},

    ),

    ege_d=>Line->nit(
      $pts{bot_l},
      $pts{bot_r},

    ),

    ege_r=>Line->nit(
      $pts{bot_r},
      $pts{top_r},

    ),

  },$class;

  return $rect;

};

# ---   *   ---   *   ---

sub edges($self) {

  return (

    $self->{ege_u},
    $self->{ege_l},
    $self->{ege_d},
    $self->{ege_r},

  );

};

# ---   *   ---   *   ---

sub draw($self) {

  for my $line($self->edges) {

    $line->draw();

  };

};

# ---   *   ---   *   ---

sub textfit($self,$lines,%O) {

  state $line_brk_re=qr[\n (?! $)]x;

  # defaults
  $O{offscreen}//=0;

  my @lines=@$lines;

  my $border=$self->{border};
  my $line_sz=$self->{sz_x}-($border*2);

  my $y_limit=$self->{sz_y}-2-$border;
  my $bot;

  if(!$O{offscreen}) {
    $bot=$y_limit;

  } else {
    $bot=@lines;

  };

  my $i=0;
  while($i<@lines && $i<$bot) {

    #if(defined !$lines[$i]) {last};

    $lines[$i]=descape($lines[$i]);
    linewrap(\$lines[$i],$line_sz);

    if($lines[$i]=~ $line_brk_re) {

      my @head=();
      my @tail=();

      if($i>0) {
        @head=@lines[0..$i-1];

      };

      if($i<$#lines) {
        @tail=@lines[$i+1..$#lines];

      };

      my @insert=split m[\n],$lines[$i];

      @lines=(@head,@insert,@tail);
      $i+=int(@insert);

    } else {$i++};

  };

  my $nul="\x{00}";
  my $us="\x{1F}";

  my $ascii_ctl=qr{[$nul-$us]}x;

  for my $line(@lines) {

    chomp $line;
    while($line=~ s[($ascii_ctl)][#:cut;>]) {

      my $escaped=$1;

      $escaped=chr(ord($1)+0x100);
      $line=~ s[#:cut;>][$escaped];

    };

  };

  return @lines;

};

# ---   *   ---   *   ---
1; # ret
