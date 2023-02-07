#!/usr/bin/perl
# ---   *   ---   *   ---
# ANSI
# tty graphics
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package GF::Mode::ANSI;

  use v5.36.0;
  use strict;
  use warnings;

  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;
  use parent 'St';

  use lib $ENV{'ARPATH'}.'/lib/';

  use Peso::Ipret;

  use GF::Rect;
  use GF::Vec4;

  use Lycon;
  binmode(STDOUT,':utf8');

# ---   *   ---   *   ---
# info

  our $VERSION=v0.00.2;#b
  our $AUTHOR='IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  sub Frame_Vars($class) {return {

    -buff   => [],

    -canvas => undef,
    -cursor => undef,

    -autoload=>[qw(

      rd ipret req

      draw color bnw
      mvcur encur

      cline
      clear

    )],

  }};

# ---   *   ---   *   ---
# gets terminal dimentions

sub ttysz() {

  my @out=(0,0);
  Lycon::ttysz(\@out);

  return @out;

};

# ---   *   ---   *   ---
# initialize canvas

sub canvas(

  # implicit
  $class,

  # actual
  $border=0,
  @sz,

) {

  # default to screen size
  @sz=(!@sz) ? ttysz() : @sz;

  my $frame=$class->new_frame();

  $frame->{-canvas}=GF::Rect->nit(

    "$sz[0]x$sz[1]",
    border=>$border

  );

  $frame->{-cursor}=GF::Vec4->nit();

  return $frame;

};

# ---   *   ---   *   ---
# reads a draw request

sub rd($class,$frame,$req) {

  my $out=$NULLSTR;

  my ($proc,$args,$ct)=(

    $req->{proc},
    $req->{args},

    $req->{ct},

  );

  $proc //= $NULLSTR;
  $args //= [];

  $ct   //= $NULLSTR;

  $out.=($proc ne $NULLSTR)
    ? $frame->$proc(@$args)
    : $NULLSTR;
    ;

  $out.=$ct;

  return $out;

};

# ---   *   ---   *   ---
# ^batch

sub ipret($class,$frame) {

  my $out  = $NULLSTR;
  my $buff = $frame->{-buff};

  for my $req(@$buff) {
    $out.=$frame->rd($req);

  };

  return $out;

};

# ---   *   ---   *   ---

sub draw($class,$frame) {

  print {*STDOUT} $frame->ipret();
  STDOUT->flush();

  $frame->{-buff}=[];

};

# ---   *   ---   *   ---
# set foreground and background color
# from single hex lit

sub color($class,$frame,@ar) {

  my $esc=$NULLSTR;

  for my $c(@ar) {

    my $fg=$c&0xF;
    my $bg=$c>>4;

    my $bold_fg=$fg>7;
    my $bold_bg=$bg>7;

    $fg&=7;$fg=30+$fg;
    $bg&=7;$bg=40+$bg;

    $bold_fg=($bold_fg) ? 1 : 22;
    $bold_bg=($bold_bg) ? 5 : 25;

    $esc.="\e[$bold_fg;${fg};$bold_bg;${bg}m";

  };

  return $esc;

};

# ---   *   ---   *   ---
# ^undo

sub bnw($class,$frame) {
  return "\e[0m";

};

# ---   *   ---   *   ---
# pushes commands to draw buffer

sub req($class,$frame,@slurp) {
  my $buff=$frame->{-buff};
  push @$buff,@slurp;

};

# ---   *   ---   *   ---

sub mvcur($class,$frame,$x,$y) {
  return "\e[" . ++$y . q[;] . ++$x . q[H];

};

# ---   *   ---   *   ---

sub encur($class,$frame,$enable) {

  my $out;

  if($enable) {
    $out="\e[?25h";

  } else {
    $out="\e[?25l";

  };

  return $out;

};

# ---   *   ---   *   ---
# clearing

sub cline($class,$frame) {return "\e[2K"};
sub clear($class,$frame) {return "\e[2J"};

# ---   *   ---   *   ---
1; # ret
