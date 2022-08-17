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

sub nit($class,$dim,$pos_x=0,$pos_y=0) {

  my ($sz_x,$sz_y)=split m[x],$dim;

  my %pts=(

    top_l=>Vec4->nit($pos_x,$pos_y),
    top_r=>Vec4->nit($pos_x+$sz_x,$pos_y),

    bot_l=>Vec4->nit($pos_x,$pos_y+$sz_y),
    bot_r=>Vec4->nit($pos_x+$sz_x,$pos_y+$sz_y),

  );

  # make new instance
  my $rect=bless {

    sz_x=>$sz_x,
    sz_y=>$sz_y,

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

sub textfit($self,$str,$border=2) {

  linewrap(

    \$str,
    $self->{sz_x}-($border*2),

    add_newlines=>0,

  );

  my ($x,$y)=@{$self->{top_l}};
  my @lines=split $NEWLINE_RE,$str;

  my $bot=$self->{sz_y}-2-$border;

  if($#lines < $bot) {
    $bot=$#lines;

  };

  @lines=@lines[0..$bot];

  for my $line(@lines) {
    $line=sprintf "\e[%i;%iH\e[2K$line",
      $y+1+$border,$x+1+$border;

    $y++;

  };

  return join $NULLSTR,@lines;

};

# ---   *   ---   *   ---
1; # ret
