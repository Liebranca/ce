#!/usr/bin/perl
# ---   *   ---   *   ---
# VEC4
# Group of four numbers xyzw
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package GF::Vec4;

  use v5.36.0;
  use strict;
  use warnings;

  use Scalar::Util qw(looks_like_number);
  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;
  use Arstd::IO;

  use parent 'St';

# ---   *   ---   *   ---
# info

  our $VERSION=v0.00.2;
  our $AUTHOR='IBN-3DILA';

# ---   *   ---   *   ---
# constructor

sub nit($class,@co) {

  my ($x,$y,$z,$w)=@co;

  # process inputs
  for my $v($x,$y,$z,$w) {

    $v//=0;

    errout(

      q[Bad input for Vec4: '%s'],
      args=>[$v],

      lvl=>$AR_FATAL,

    ) unless looks_like_number($v);

  };

  my $pt=bless [$x,$y,$z,$w],$class;

  return $pt;

};

# ---   *   ---   *   ---
# compare two points

sub equals($self,$other) {

  my $out = 0;
  my $i   = 0;

  map {

    $ARG//=0;
    $out+=$self->[$i++] eq $ARG;

  } @$other;

  return $out==4;

};

# ---   *   ---   *   ---
# get distance between two points

sub dist($self,$other) {

  my ($x0,$y0,$z0,$w0)=@$self;
  my ($x1,$y1,$z1,$w1)=@$other;

  return sqrt(

    ($x0-$x1)**2
  + ($y0-$y1)**2
  + ($z0-$z1)**2
  + ($w0-$w1)**2

  );

};

# ---   *   ---   *   ---
# ^shortest out of point array

sub nearest($self,@ar) {

  my @dist = map {$self->dist($ARG)} @ar;

  my $i    = 0;
  my $near = 9999;

  for my $j(0..$#dist) {

    my $d=$dist[$j];

    if($d<$near) {
      $i=$j;
      $near=$d;

    };

  };

  return ($ar[$i],$i);

};

# ---   *   ---   *   ---

sub submax($a,$b) {

  my $out;

  if($a<$b) {$out=$b-$a}
  else {$out=$a-$b};

  return $out;

};

sub minus($self,$other) {

  my $class = ref $self;
  my $i     = 0;

  return $class->nit(map {
    $self->[$i++]-$ARG

  } @$other);

};

# ---   *   ---   *   ---

sub clamp_step($self,$other,$by=1) {

  my ($x0,$y0,$z0,$w0)=@$self;
  my ($x1,$y1,$z1,$w1)=@$other;

  my @result=();

  for my $i(0..3) {

    my $c0=$self->[$i];
    my $c1=$other->[$i];

    my $step=$c1-$c0;
    $step/=$by if $step!=0;

    push @result,$step;

  };

  return @result;

};

# ---   *   ---   *   ---

sub behind_1D($self,$other) {
  return ($self->[0] < $other->[0])
  && ($self->[1] == $other->[1]);

};

sub behind_2D($self,$other) {

  return

     (  ($self->[0] < $other->[0])
     && ($self->[1] <= $other->[1]) )

  || ($self->[1] < $other->[1])

  ;

};

# ---   *   ---   *   ---

sub offset($self,@by) {

  my $i=0;
  while($i<@$self) {

    $by[$i]//=0;
    $by[$i]=$self->[$i]+$by[$i];

    $i++;

  };

  return $self->get_class()->nit(@by);

};

# ---   *   ---   *   ---

sub least($self,$other) {

  return ($self,$other) if $self->behind_2D($other);
  return ($other,$self);

};

sub over($self,$other) {

  my $out=0;
  my $i=0;

  for my $i(0..@$self-1) {
    $out|=$self->[$i]!=$other->[$i]

  };

  return $out;

};

# ---   *   ---   *   ---
# debug out

sub srepr($self,$n=4) {
  my $out=join q[,],@{$self}[0..$n-1];
  return "[$out]";

};

# ---   *   ---   *   ---
# get byte at vector position
# for ctlproc

sub sput($self,%O) {

  $O{char}  //= q[#];
  $O{color} //= 0x07;

  my ($x,$y)=@$self;

  my $req_a={
    proc => 'mvcur',
    args => [int($y+1),int($x+1)],

  };

  my $req_b={

    proc => 'color',
    args => [$O{color}],

    ct   => $O{char},

  };

  return ($req_a,$req_b);

};

# ---   *   ---   *   ---
1; # ret
