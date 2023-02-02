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
package GF::Rect;

  use v5.36.0;
  use strict;
  use warnings;

  use English qw(-no_match_vars);
  use Carp;

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;

  use Arstd::String;
  use Arstd::Array;
  use Arstd::IO;

  use parent 'St';

  use lib $ENV{'ARPATH'}.'/lib/';
  use GF::Vec4;
  use GF::Line;

# ---   *   ---   *   ---
# constructor

sub nit(

  # implicit
  $class,

  # actual
  $dim,%O

) {

  # defaults
  $O{pos_x}   //= 0;
  $O{pos_y}   //= 0;
  $O{border}  //= 2;
  $O{e_char}  //= undef;

  my ($sz_x,$sz_y)=split m[x],$dim;

  my %pts=(

    top_l=>GF::Vec4->nit(
      $O{pos_x},$O{pos_y}

    ),

    top_r=>GF::Vec4->nit(
      $O{pos_x}+$sz_x,$O{pos_y}

    ),

    bot_l=>GF::Vec4->nit(
      $O{pos_x},$O{pos_y}+$sz_y

    ),

    bot_r=>GF::Vec4->nit(
      $O{pos_x}+$sz_x,$O{pos_y}+$sz_y

    ),

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

    ege_u=>GF::Line->nit(
      $pts{top_l},
      $pts{top_r},

    ),

    ege_l=>GF::Line->nit(
      $pts{top_l},
      $pts{bot_l},

    ),

    ege_d=>GF::Line->nit(
      $pts{bot_l},
      $pts{bot_r},

    ),

    ege_r=>GF::Line->nit(
      $pts{bot_r},
      $pts{top_r},

    ),

    lines=>[],
    e_char=>$O{e_char},

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

sub textfit($self,$lines,%O) {

  state $line_brk_re=qr[\n (?! $)]x;

  # defaults
  $O{offscreen}//=0;

  # wipe previous
  $self->{lines}=[];

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

  map {$ARG=$NULLSTR if !defined $ARG} @lines;

  my $i=0;
  while($i<@lines && $i<$bot) {

    $lines[$i]=descape($lines[$i]);
    linewrap(\$lines[$i],$line_sz);

    if($lines[$i]=~ $line_brk_re) {

      my @ins=split m[\n],$lines[$i];

      array_insert(\@lines,$i,@ins);
      $i+=int(@ins);

    } else {$i++};

  };

  my $nul = "\x{00}";
  my $us  = "\x{1F}";

  my $ascii_ctl=qr{[$nul-$us]}x;

  for my $line(@lines) {

    chomp $line;
    while($line=~ s[($ascii_ctl)][#:cut;>]) {

      my $escaped=$1;

      $escaped=chr(ord($1)+0x100);
      $line=~ s[#:cut;>][$escaped];

    };

  };

  @{$self->{lines}}=@lines;

};

# ---   *   ---   *   ---
# give command for re-drawing
# content inside the rect

sub update_lines($self) {

  # initial position of text
  my ($x,$y) = (1,0);
  $x+=$self->{border};
  $y+=$self->{border};

  # apply cursor movement
  # to copy of current content
  return map {$ARG=

    q[$:gd_mvcur ].

      ($self->{pos_y}+($y++)+1).q{,}.
      ($self->{pos_x}+$x+1).

    q[;>].$ARG;

  } @{$self->{lines}};

};

# ---   *   ---   *   ---
# give redraw cmd for the
# edges of the rect

sub update_edges($self) {

  my @edges  = map {
    $ARG->update(char=>$self->{e_char})

  } $self->edges();

};

# ---   *   ---   *   ---
# outs draw commands for ctlproc

sub update($self) {

  return (
    $self->update_lines(),
    $self->update_edges(),

  );

};

# ---   *   ---   *   ---
1; # ret
