#!/usr/bin/perl
# ---   *   ---   *   ---
# TEXT
# Lods o escapes
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package GF::Text;

  use v5.36.0;
  use strict;
  use warnings;

  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;
  use Arstd::Array;

  use parent 'St';

  use lib $ENV{'ARPATH'}.'/lib/';
  use GF::Vec4;

# ---   *   ---   *   ---
# info

  our $VERSION=v0.00.1;
  our $AUTHOR='IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  sub Frame_Vars($class) {return {

    -rect=>undef,
    -lines=>[],

    -autoload=>[qw(

      escape_at descape apply_escapes flat

    )],

  }};

# ---   *   ---   *   ---
# constructor

sub nit($class,$frame,$s,$y) {

  my $line=bless {

    modified=>$s,
    original=>$s,

    escapes=>[],

    frame=>$frame,

  },$class;

  $frame->{-lines}->[$y]=$line;

  return $line;

};

# ---   *   ---   *   ---

sub escape_at(

  # implicit
  $class,$frame,

  # actual
  $co,
  $seq,

) {

  my ($x,$y)=@$co;

  my $line=$frame->{-lines}->[$y];
  push @{$line->{escapes}},[$x=>$seq];

};

sub descape($class,$frame,$y,$pat) {

  my $line=$frame->{-lines}->[$y];

  for my $e(@{$line->{escapes}}) {

    if($e->[1]=~ m[$pat]) {
      $e=undef;

    };

  };

  array_filter($line->{escapes});

};

# ---   *   ---   *   ---

sub apply_escapes($class,$frame) {

  my $sz=$frame->{-rect}->{sz_x};

  for my $line(@{$frame->{-lines}}) {

    my $escapes=$line->{escapes};
    my $x_mod=0;

    $line->{modified}=sprintf

      "%-${sz}s",
      $line->{original}

    ;

    @$escapes=sort {$a->[0]<=>$b->[0]} @$escapes;

    for my $e(@$escapes) {

      my ($pos,$seq)=@$e;

      substr $line->{modified},$pos+$x_mod,0,$seq;

      $x_mod+=length $seq;

    };

  };

};

# ---   *   ---   *   ---

sub flat($class,$frame) {

  $frame->apply_escapes();

  return join $NULLSTR,map {
    $ARG->{modified}

  } @{$frame->{-lines}};

};

# ---   *   ---   *   ---
1; # ret
