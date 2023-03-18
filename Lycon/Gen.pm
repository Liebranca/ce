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

# ---   *   ---   *   ---
# info

  our $VERSION = v0.00.2;#b
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# template: movement

sub mvdec($co,$ax,$limit) {
  my $ref  = \$co->[$ax];
  $$ref   -= 1*($$ref > $limit->[$ax]->[0]);

};

sub mvinc($co,$ax,$limit) {
  my $ref  = \$co->[$ax];
  $$ref   += 1*($$ref < $limit->[$ax]->[1]-1);

};

# ---   *   ---   *   ---
# generator: 2d movement

sub wasd($co,$limit,%O) {

  # defaults
  $O{tap}//=1;
  $O{hel}//=1;
  $O{rel}//=0;

  my @out=();

  # make callback array
  my @cba=(
    sub () {mvdec($co,1,$limit)}, # w
    sub () {mvdec($co,0,$limit)}, # a
    sub () {mvinc($co,1,$limit)}, # s
    sub () {mvinc($co,0,$limit)}, # d

  );

  # ^assign to out struct
  map {

    my $fn=shift @cba;

    push @out,$ARG=>[
      ($O{tap}) ? $fn : 0,
      ($O{hel}) ? $fn : 0,
      ($O{rel}) ? $fn : 0,

    ];

  } qw(w a s d);

  # give (key=>[callbacks])
  return @out;

};

# ---   *   ---   *   ---
1; # ret
