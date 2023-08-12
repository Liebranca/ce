#!/usr/bin/perl
# ---   *   ---   *   ---
# ICON
# Bits of ROM
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package GF::Icon;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;
  use English qw(-no_match-vars);
  use List::Util qw(min max);

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;
  use Arstd::IO;

  use parent 'St';

# ---   *   ---   *   ---
# info

  our $VERSION=v0.00.1;#b
  our $AUTHOR='IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly our $FILE        => chr(0x100+0x01);
  Readonly our $FILE_BLANK  => chr(0x100+0x00);
  Readonly our $FILE_LINK   => chr(0x100+0x02);

  Readonly our $BLK_AUDIO   => chr(0x100+0x06);
  Readonly our $BLK_CROSS   => chr(0x100+0x03);

  Readonly our $DIR         => chr(0x100+0x05);
  Readonly our $DIR_EMPTY   => chr(0x100+0x04);
  Readonly our $DIR_UP      => chr(0x100+0x07);
  Readonly our $DIR_BACK    => chr(0x100+0x08);
  Readonly our $RELOAD      => chr(0x100+0x09);

  Readonly our $RESTART     => chr(0x100+0x0A);
  Readonly our $REWIND      => chr(0x100+0x0B);
  Readonly our $PAUSE       => chr(0x100+0x0C);
  Readonly our $PLAY        => chr(0x100+0x0D);
  Readonly our $FASTFWD     => chr(0x100+0x0E);
  Readonly our $PREVIOS     => chr(0x100+0x0F);
  Readonly our $NEXT        => chr(0x100+0x11);

  Readonly our $ARROW_UP    => chr(0x100+0x12);
  Readonly our $ARROW_BLK   => chr(0x100+0x13);
  Readonly our $ARROW_DOWN  => chr(0x100+0x14);
  Readonly our $ARROW_LEFT  => chr(0x100+0x15);
  Readonly our $ARROW_RIGHT => chr(0x100+0x16);

  Readonly our $SAVEGAME    => chr(0x100+0x17);
  Readonly our $CONFIG      => chr(0x100+0x18);

  Readonly our $RND_RD      => chr(0x100+0x19);

  Readonly our $CORA_LD     => chr(0x100+0x1A);
  Readonly our $CORA_RD     => chr(0x100+0x1B);
  Readonly our $CORA_RU     => chr(0x100+0x1C);
  Readonly our $CORA_LU     => chr(0x100+0x1D);

  Readonly our $NOTE        => chr(0x100+0x1E);
  Readonly our $LYEB        => chr(0x100+0x1F);

# ---   *   ---   *   ---
# heart

  Readonly our $PAIN_S0     => chr(0x100+0x7F);
  Readonly our $PAIN_S1     => chr(0x100+0x80);
  Readonly our $PAIN_S2     => chr(0x100+0x81);
  Readonly our $PAIN_S3     => chr(0x100+0x82);
  Readonly our $PAIN_S4     => chr(0x100+0x83);
  Readonly our $PAIN_S5     => chr(0x100+0x84);
  Readonly our $PAIN_DED    => chr(0x100+0x85);
  Readonly our $PAIN_BLESS  => chr(0x100+0x86);
  Readonly our $PAIN_HIT0   => chr(0x100+0x8F);
  Readonly our $PAIN_HIT1   => chr(0x100+0x93);

  Readonly our $PAIN => [

    $PAIN_S0,$PAIN_S1,$PAIN_S2,
    $PAIN_S3,$PAIN_S4,$PAIN_S5,

    $PAIN_DED

  ];

# ---   *   ---   *   ---
# shield

  Readonly our $ARMA_S0     => chr(0x100+0x87);
  Readonly our $ARMA_S1     => chr(0x100+0x88);
  Readonly our $ARMA_S2     => chr(0x100+0x89);
  Readonly our $ARMA_S3     => chr(0x100+0x8A);
  Readonly our $ARMA_S4     => chr(0x100+0x8B);
  Readonly our $ARMA_S5     => chr(0x100+0x8C);
  Readonly our $ARMA_DED    => chr(0x100+0x8D);
  Readonly our $ARMA_BLESS  => chr(0x100+0x8E);
  Readonly our $ARMA_HIT0   => chr(0x100+0x90);
  Readonly our $ARMA_HIT1   => chr(0x100+0x94);
  Readonly our $ARMA_GUARD  => chr(0x100+0x9A);

# ---   *   ---   *   ---
# round little "wait" anim

  Readonly our $TASK_S0     => chr(0x100+0x99);
  Readonly our $TASK_S1     => chr(0x100+0x98);
  Readonly our $TASK_S2     => chr(0x100+0x97);
  Readonly our $TASK_S3     => chr(0x100+0x96);
  Readonly our $TASK_S4     => chr(0x100+0x95);

# ---   *   ---   *   ---
# eyes

  Readonly our $EYEL_S0     => chr(0x100+0x9B);
  Readonly our $EYEL_S1     => chr(0x100+0x9C);
  Readonly our $EYEL_S2     => chr(0x100+0x9D);
  Readonly our $EYEL_S3     => chr(0x100+0x9E);
  Readonly our $EYEL_CLOSE  => chr(0x100+0x9F);
  Readonly our $EYEL_CHANT  => chr(0x100+0xA0);

  Readonly our $EYER_S0     => chr(0x100+0xA3);
  Readonly our $EYER_S2     => chr(0x100+0xA4);
  Readonly our $EYER_S1     => chr(0x100+0xA5);
  Readonly our $EYER_S3     => chr(0x100+0xA6);
  Readonly our $EYER_CLOSE  => chr(0x100+0xA7);
  Readonly our $EYER_CHANT  => chr(0x100+0xA8);

# ---   *   ---   *   ---
# wallclock

  Readonly our $CLOCK_S0    => chr(0x100+0xA9);
  Readonly our $CLOCK_S1    => chr(0x100+0xAA);
  Readonly our $CLOCK_S2    => chr(0x100+0xAB);
  Readonly our $CLOCK_S3    => chr(0x100+0xAC);
  Readonly our $CLOCK_S4    => chr(0x100+0xAD);
  Readonly our $CLOCK_S5    => chr(0x100+0xAE);
  Readonly our $CLOCK_S6    => chr(0x100+0xAF);
  Readonly our $CLOCK_S7    => chr(0x100+0xB0);

# ---   *   ---   *   ---
# battery

  Readonly our $TANK_S0     => chr(0x100+0xB1);
  Readonly our $TANK_S1     => chr(0x100+0xB2);
  Readonly our $TANK_S2     => chr(0x100+0xB3);
  Readonly our $TANK_S3     => chr(0x100+0x92);
  Readonly our $TANK_S4     => chr(0x100+0xB5);
  Readonly our $TANK_S5     => chr(0x100+0xB6);
  Readonly our $TANK_DED    => chr(0x100+0xB7);
  Readonly our $TANK_BLESS  => chr(0x100+0xB8);
  Readonly our $TANK_H      => chr(0x100+0x10);

  Readonly our $TANK =>[

    $TANK_S0,$TANK_S1,$TANK_S2,
    $TANK_S3,$TANK_S4,$TANK_S5,

    $TANK_DED,

  ];

# ---   *   ---   *   ---
# diamond

  Readonly our $DIAM        => chr(0x100+0xB9);
  Readonly our $SNOWFLAKE   => chr(0x100+0xBA);
  Readonly our $DIAM_H      => chr(0x100+0xBB);
  Readonly our $DIAM_V      => chr(0x100+0xBC);
  Readonly our $DIAM_BLESS  => chr(0x100+0xBD);
  Readonly our $DIAM_DED    => chr(0x100+0xBE);
  Readonly our $DIAM_RND    => chr(0x100+0xBF);

# ---   *   ---   *   ---
# border: single

  Readonly our $BOR0_H      => chr(0x100+0xC0);
  Readonly our $BOR0_UL     => chr(0x100+0xC1);
  Readonly our $BOR0_DL     => chr(0x100+0xC2);
  Readonly our $BOR0_DR     => chr(0x100+0xC3);
  Readonly our $BOR0_X      => chr(0x100+0xC4);
  Readonly our $BOR0_UR     => chr(0x100+0xC5);

  Readonly our $BOR0_XL     => chr(0x100+0xC6);
  Readonly our $BOR0_XR     => chr(0x100+0xC7);
  Readonly our $BOR0_XU     => chr(0x100+0xC8);
  Readonly our $BOR0_XD     => chr(0x100+0xC9);

# ---   *   ---   *   ---
# border: double

  Readonly our $BOR1_H      => chr(0x100+0xCA);
  Readonly our $BOR1_UL     => chr(0x100+0xCB);
  Readonly our $BOR1_DL     => chr(0x100+0xCC);
  Readonly our $BOR1_UR     => chr(0x100+0xCD);
  Readonly our $BOR1_DR     => chr(0x100+0xCE);
  Readonly our $BOR1_V      => chr(0x100+0xCF);

  Readonly our $BOR1_X      => chr(0x100+0xD0);
  Readonly our $BOR1_XR     => chr(0x100+0xD1);
  Readonly our $BOR1_XL     => chr(0x100+0xD2);
  Readonly our $BOR1_XD     => chr(0x100+0xD3);
  Readonly our $BOR1_XU     => chr(0x100+0xD4);

# ---   *   ---   *   ---

  Readonly our $TOMB_CROSS  => chr(0x100+0xD5);
  Readonly our $TOMB_PLAQUE => chr(0x100+0xD6);
  Readonly our $HOLY        => chr(0x100+0xD7);
  Readonly our $SKULL_THIN  => chr(0x100+0xD8);
  Readonly our $SKULL_FAT   => chr(0x100+0xD9);

  Readonly our $ACE         => chr(0x100+0xDA);
  Readonly our $CRYSTAL_DED => chr(0x100+0xDB);
  Readonly our $CRYSTAL     => chr(0x100+0xDC);

# ---   *   ---   *   ---

  Readonly our $SQ_DED      => chr(0x100+0xDE);
  Readonly our $SQ_BLESS    => chr(0x100+0xDF);
  Readonly our $SQ_TILE0    => chr(0x100+0xE0);
  Readonly our $SQ_TILE1    => chr(0x100+0xE1);
  Readonly our $SQ_SOLID    => chr(0x100+0xE2);
  Readonly our $SQ_THIN     => chr(0x100+0xE3);
  Readonly our $SQ_TILE2    => chr(0x100+0xE4);
  Readonly our $SQ_TILE3    => chr(0x100+0xE5);

# ---   *   ---   *   ---
# fx

  Readonly our $BLESS0      => chr(0x100+0xE9);
  Readonly our $BLESS1      => chr(0x100+0xEA);
  Readonly our $BLESS2      => chr(0x100+0xEB);
  Readonly our $BLESS3      => chr(0x100+0xEC);

  Readonly our $HLINES      => chr(0x100+0xE6);
  Readonly our $WAVES0      => chr(0x100+0xE7);
  Readonly our $WAVES1      => chr(0x100+0xE8);

# ---   *   ---   *   ---
# mapping

  Readonly our $GRASSDIRT   => chr(0x100+0x91);
  Readonly our $BUSH        => chr(0x100+0xED);
  Readonly our $FLOWER      => chr(0x100+0xEE);

# ---   *   ---   *   ---
# random

  Readonly our $ACUTE       => chr(0x100+0xB4);
  Readonly our $DIAMETER    => chr(0x100+0xDD);
  Readonly our $IVEXCLAM    => chr(0x100+0xA1);
  Readonly our $CENT        => chr(0x100+0xA2);
  Readonly our $NSPACE      => chr(0x100+0xFF);

# ---   *   ---   *   ---
# easter egg

  Readonly our $DAL         => chr(0x100+0xEF);
  Readonly our $YA          => chr(0x100+0xF0);

  Readonly our $BLESS4      => chr(0x100+0xF1);

  Readonly our $KAF         => chr(0x100+0xF2);
  Readonly our $DHAL        => chr(0x100+0xF3);
  Readonly our $FA          => chr(0x100+0xF4);
  Readonly our $H7A         => chr(0x100+0xF5);
  Readonly our $A3YN        => chr(0x100+0xF6);

  Readonly our $PAL0        => chr(0x100+0xF7);
  Readonly our $PAL1        => chr(0x100+0xF8);
  Readonly our $PAL2        => chr(0x100+0xF9);
  Readonly our $PAL3        => chr(0x100+0xFA);
  Readonly our $PAL4        => chr(0x100+0xFB);
  Readonly our $PAL5        => chr(0x100+0xFC);
  Readonly our $PAL6        => chr(0x100+0xFD);
  Readonly our $PAL7        => chr(0x100+0xFE);

# ---   *   ---   *   ---
# cstruc for animations

sub new($class,$anim,%O) {

  # defaults
  $O{rate} //= 16;


  # make ice
  my $self=bless {

    buf   => [@$anim],

    len   => int @$anim,
    rate  => 1/$O{rate},

    i     => 0,
    cchar => $anim->[0],

  },$class;

  return $self;

};

# ---   *   ---   *   ---
# ^play anim

sub play($self,$step=1) {

  $self->{i} += $self->{rate} / $step;
  $self->{i} *= $self->{i} < $self->{len};

  return $self->get_cchar();

};

# ---   *   ---   *   ---
# ^without looping

sub play_stop($self,$step=1) {

  $self->{i} += $self->{rate} / $step;

  $self->{i}  = $self->{len}-1
  if $self->{i} > $self->{len};

  return $self->get_cchar();

};

# ---   *   ---   *   ---
# ^in reverse

sub rewind($self,$step=1) {

  $self->{i} -= $self->{rate} / $step;
  $self->{i} *= $self->{i} >= 0;

  return $self->get_cchar();

};

# ---   *   ---   *   ---
# ^gets current frame

sub get_cchar($self) {

  my $i=max(0,min($self->{i},$self->{len}-1));

  $self->{cchar}=
    $self->{buf}->[int $i];

  return $self->{cchar};

};

# ---   *   ---   *   ---
1; # ret
