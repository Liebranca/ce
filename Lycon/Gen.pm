#!/usr/bin/perl
# ---   *   ---   *   ---
# LYCON GEN
# Generators for generics
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package Lycon::Gen;

  use v5.36.0;
  use strict;
  use warnings;

  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;

  use Arstd::String;
  use Arstd::IO;

  use lib $ENV{'ARPATH'}.'/lib/';

  use Lycon;
  use Lycon::Kbd;

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.4;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# set a list of keys to nop

sub clear(@keys) {
  return map {$ARG=>[0,0,0]} @keys;

};

# ---   *   ---   *   ---
# template: movement

sub mvdec($sref,$co,$dim,$ax) {

  my $src  = $$sref;

  my $ref  = \$src->{$co}->[$ax];
  $$ref   -= 1*($$ref > $src->{$dim}->[$ax]->[0]);

};

sub mvinc($sref,$co,$dim,$ax) {

  my $src  = $$sref;

  my $ref  = \$src->{$co}->[$ax];
  $$ref   += 1*($$ref < $src->{$dim}->[$ax]->[1]-1);

};

# ---   *   ---   *   ---
# generator: 2d movement

sub mv2d($src,$co,$dim,%O) {

  # defaults
  $O{tap}  //= 1;
  $O{hel}  //= 1;
  $O{rel}  //= 0;
  $O{keys} //= [qw(w a s d)];

  my @out=();

  # make callback array
  my @cba=(

    # up,down,left,right
    sub () {mvdec($src,$co,$dim,1)},
    sub () {mvdec($src,$co,$dim,0)},
    sub () {mvinc($src,$co,$dim,1)},
    sub () {mvinc($src,$co,$dim,0)},

  );

  # ^assign to out struct
  map {

    my $fn=shift @cba;

    push @out,$ARG=>[
      ($O{tap}) ? $fn : 0,
      ($O{hel}) ? $fn : 0,
      ($O{rel}) ? $fn : 0,

    ];

  } @{$O{keys}};

  # give (key=>[callbacks])
  return @out;

};

# ---   *   ---   *   ---
# ^ice

sub wasd($src,$co,$dim,%O) {
  $O{keys}=[qw(w a s d)];
  return mv2d($src,$co,$dim,%O);

};

sub arrows($src,$co,$dim,%O) {
  $O{keys}=[qw(up left down right)];
  return mv2d($src,$co,$dim,%O);

};

# ---   *   ---   *   ---
# enables text input

sub TI($st) {

  state $re=qr{
    (?<key> [^\s]+) \s+
    (?<lc>  [^\s]+) \s+
    (?<uc>  [^\s]+) \s+
    (?<mc>  [^\s]+) \s+

  }x;

  state $num=qr{^\$[0-9A-Fa-f]+$};

  my @out  = ();
  my $body = orc($st->{fname});


  # ^expr split
  while($body=~ s[$re][]) {

    my $key = $+{key};
    my $lc  = $+{lc};
    my $uc  = $+{uc};
    my $mc  = $+{mc};

    # transform numerical
    ($lc,$uc,$mc)=map {

      ($ARG=~ $num)
        ? chr(sstoi($ARG))
        : $ARG
        ;

    } ($lc,$uc,$mc);

    my $fn  = sub {

      state @ar=($lc,$uc,$mc,$mc);

      Lycon::keycool();

      my $i=
        ($st->{lshift} << 0)
      | ($st->{ralt}   << 1)
      ;

      $st->{buf} .= $ar[$i];

    };

    push @out,$key=>[$fn,0,0];

  };


  # ^special cased keys
  my $gen=sub ($c) { return sub {
    Lycon::keycool();
    $st->{buf} .= $c;

  }};

  push @out,(

    ret       => [($gen->("\n")) x 2,0],

    space     => [($gen->(" ")) x 2,0],
    backspace => [($gen->("\b")) x 2,0],

    LShift    => [

      sub {$st->{lshift}=1},

      0,
      sub {$st->{lshift}=0},

    ],

    RAlt      => [

      sub {$st->{ralt}=1},

      0,
      sub {$st->{ralt}=0},

    ],

  );


  return @out;

};

# ---   *   ---   *   ---
1; # ret
