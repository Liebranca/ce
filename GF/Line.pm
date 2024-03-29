#!/usr/bin/perl
# ---   *   ---   *   ---
# LINE
# Connects two points
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package GF::Line;

  use v5.36.0;
  use strict;
  use warnings;

  use Carp;

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;
  use Arstd::IO;

  use parent 'St';

  use lib $ENV{'ARPATH'}.'/lib/';
  use GF::Vec4;

# ---   *   ---   *   ---
# constructor

sub nit($class,$a,$b) {

  # process inputs
  for my $co($a,$b) {

    $co=GF::Vec4->nit(@$co)
    unless GF::Vec4->is_valid($co);

  };

  # make new instance
  my $line=bless [$a,$b],$class;

  return $line;

};

# ---   *   ---   *   ---

sub get_range($self) {

  my ($beg,$end)=@$self;
  my $dist=$beg->dist($end);

  my $num_pts=int($dist);

  my $x=$beg->[0];
  my $y=$beg->[1];

  my ($x_step,$y_step)=
    $beg->clamp_step($end,$dist);

  my @pts=($beg);

  for my $i(1..$num_pts) {

    $x+=$x_step;
    $y+=$y_step;

    push @pts,GF::Vec4->nit($x,$y);

  };

  push @pts,$end;
  return @pts;


};

# ---   *   ---   *   ---
# outs draw commands for ctlproc

sub sput($self,%O) {

  # defaults
  $O{char}  //= q[.];
  $O{color} //= 0x07;

  my @out=();

  for my $pt($self->get_range()) {

    my ($x,$y)=@$pt;

    my $req_a={
      proc => 'mvcur',
      args => [int($y+1),int($x+1)],

    };

    my $req_b={
      proc => 'color',
      args => [$O{color}],

      ct   => $O{char},

    };

    push @out,$req_a,$req_b;

  };

  return @out;

};

# ---   *   ---   *   ---
1; # ret
