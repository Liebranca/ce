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
package Graphics::ANSI;

  use v5.36.0;
  use strict;
  use warnings;

  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;
  use parent 'St';

  use lib $ENV{'ARPATH'}.'/lib/';

  use Peso::Ipret;

  use Rect;
  use Vec4;

# ---   *   ---   *   ---
# info

  our $VERSION=v0.00.1;
  our $AUTHOR='IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  sub Frame_Vars($class) {return {

    -buff=>$NULLSTR,
    -canvas=>undef,
    -cursor=>undef,

    -autoload=>[qw(

      draw color
      mvcur encur

      cline

    )],

  }};

# ---   *   ---   *   ---

sub nit(

  # implicit
  $class,$frame,

  # actual
  $sz_x,$sz_y,
  $border

) {

  $frame->{-canvas}=Rect->nit(

    "${sz_x}x${sz_y}",
    border=>$border

  );

  $frame->{-cursor}=Vec4->nit();

};

# ---   *   ---   *   ---

sub draw($class,$frame,%ctx) {

  my $buff=$frame->{-buff};

  Peso::Ipret::pesc(

    \$buff,
    %ctx,

  );

  print {*STDOUT} $buff;
  STDOUT->flush();

  $frame->{-buff}=$NULLSTR;

};

# ---   *   ---   *   ---

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

sub mvcur($class,$frame,@ar) {
  return "\e[".(join ';',@ar).'H';

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

sub cline($class,$frame) {return "\e[2K"};

# ---   *   ---   *   ---
1; # ret
