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
# just for debug purposes
# drawing functions belong on the ctlproc

sub draw($self) {

  my @pts=$self->get_range();
  for my $pt(@pts) {

    my ($x,$y)=@$pt;

    printf "\e[%i;%iH*",int($y)+1,int($x)+1;

  };

  print "\n";

};

# ---   *   ---   *   ---
1; # ret
