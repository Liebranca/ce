#!/usr/bin/perl
# ---   *   ---   *   ---
# LYCON KEYBOARD
# Wraps and shorcuts for the
# Lycon keyboard controller
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package Lycon::Kbd;

  use v5.36.0;
  use strict;
  use warnings;

  use Readonly;

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;
  use Arstd;
  use Chk;

  use lib $ENV{'ARPATH'}.'/lib/';

  use Genks;

# ---   *   ---   *   ---
# ROM

  Readonly my $E_NOKEY=>
    q{%s <%s> is not bound};

  Readonly my $E_YESKEY=>
    q{%s <%s> is already bound};

# ---   *   ---   *   ---
# global state

  my @Keys=();
  my %Keys=();

  my @SwKeys=();
  my %KeyIDs=();

  our $Initialized=0;

# ---   *   ---   *   ---
# common errorchk

sub define_catch($has,$inv,$type,$key) {

  # catch not bound
  if(!$has && $inv) {

    Arstd::errout(
      $E_NOKEY,

      args=>[$type,$key],
      calls=>[\&Lycon::Dpy::end],

    );

  # catch already bound
  } elsif($has && !$inv) {

    Arstd::errout(
      $E_YESKEY,

      args=>[$type,$key],
      calls=>[\&Lycon::Dpy::end],

    );

  };

};

# ---   *   ---   *   ---
# ^shorthands

sub haskey($key,$inv) {

  my $has=exists $Keys{$key};
  define_catch($has,$inv,'Key',$key)

};

sub hasid($id,$inv) {

  my $has=exists $KeyIDs{$id};
  define_catch($has,$inv,'KeyID',$id)

};

# ---   *   ---   *   ---
# add a key to the event list

sub define(

  $key,$id,

  $onTap=undef,
  $onHel=undef,
  $onRel=undef,

) {

  haskey($key,0);
  hasid($id,0);

  $KeyIDs{$id}=$key;

  push @Keys,$key=>[$id,$onTap,$onHel,$onRel];

};

# ---   *   ---   *   ---
# swap out callbacks on this key

sub redef(

  $key,

  $onTap=undef,
  $onHel=undef,
  $onRel=undef,

) {

  haskey($key,1);

  my $idex=($Keys{$key}*2)+1;

  $Keys[$idex]->[1]=($onTap)
    ? $onTap : $Keys[$idex]->[1];

  $Keys[$idex]->[2]=($onHel)
    ? $onHel : $Keys[$idex]->[2];

  $Keys[$idex]->[3]=($onRel)
    ? $onRel : $Keys[$idex]->[3];

};

# ---   *   ---   *   ---
# get access by internal ID

sub key_by_id($id) {

  hasid($id,1);

  my $key=$KeyIDs{$id};

  return $key;

};

# ---   *   ---   *   ---
# ^save and redef by internal ID

sub sv_by_id($id,@args) {

  my $key=key_by_id($id);

  my $calls=svdef($key);
  redef($key,@args);

  return [$key,$calls];

};

# ---   *   ---   *   ---
# store callbacks on this key

sub svdef($key) {

  haskey($key,1);

  my $idex=($Keys{$key}*2)+1;

  return [

    $Keys[$idex]->[1],
    $Keys[$idex]->[2],
    $Keys[$idex]->[3],

  ];

};

# ---   *   ---   *   ---
# ^restore saved callbacks

sub lddef($key,$calls) {

  haskey($key,1);

  my $idex=($Keys{$key}*2)+1;

  $Keys[$idex]->[1]=$calls->[0];
  $Keys[$idex]->[2]=$calls->[1];
  $Keys[$idex]->[3]=$calls->[2];

};

# ---   *   ---   *   ---
# register events

sub nit() {

  %Keys=@Keys;

  # check that reserved keys are mapped
  my $chk=Lycon::Ctl::all_used_keys();

  my @ids=Arstd::array_keys($chk);
  my @keys=Arstd::array_values($chk);

  while(@ids && @keys) {

    my $id=shift @ids;
    my $key=shift @keys;

    # set blank callbacks if reserved && unused
    if(!exists $KeyIDs{$id}) {

      define(

        $key,$id,

        $NULLSTR,
        $NULLSTR,
        $NULLSTR

      );

    };

  };

# ---   *   ---   *   ---
# register the events

  %Keys=@Keys;
  Lycon::keynt(Genks::pl_keymap(\@Keys,\%Keys));

  # load callbacks
  ldkeys();

};

# ---   *   ---   *   ---
# load defined callbacks

sub ldkeys() {

  for(my $x=1;$x<@Keys;$x+=2) {

    my $name=$Keys[$x-1];
    my @ar=@{$Keys[$x]}[1..3];

    my $i=0;

# ---   *   ---   *   ---
# convert perl subs to closures
# ie, callable from C

    for my $ev(@ar) {

      if(is_coderef($ev)) {
        my $cev=Lycon::FFI_Instance->closure($ev);
        $cev->sticky();

        Lycon::keycall($Keys{$name},$i,$cev);

      };

      $i++;

    };

  };

};

# ---   *   ---   *   ---
1; # ret
