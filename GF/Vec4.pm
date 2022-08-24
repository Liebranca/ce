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

sub submax($a,$b) {

  my $out;

  if($a<$b) {$out=$b-$a}
  else {$out=$a-$b};

  return $out;

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
1; # ret
