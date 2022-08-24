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

  use English qw(-no_match_vars);
  use Readonly;

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;

  use Arstd::Array;
  use Arstd::IO;

  use Chk;

  use lib $ENV{'ARPATH'}.'/lib/';

  use Lycon;
  use Lycon::Ctl;

  use Genks;

# ---   *   ---   *   ---
# adds to your namespace

  use Exporter 'import';
  our @EXPORT=qw(

    keytap keyhel keyrel

  );

# ---   *   ---   *   ---
# info

  our $VERSION=v5.36.0;
  our $AUTHOR='IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly my $E_NOKEY=>
    q{%s <%s> is not bound};

  Readonly my $E_YESKEY=>
    q{%s <%s> is already bound};

# ---   *   ---   *   ---
# global state

  my @Keys=();
  our %Keys=();

  my @SwKeys=();
  my %KeyIDs=();

  our $Initialized=0;

# ---   *   ---   *   ---
# common errorchk

sub define_catch($has,$inv,$type,$key) {

  # catch not bound
  if(!$has && $inv) {

    errout(
      $E_NOKEY,

      args=>[$type,$key],
      calls=>[\&Lycon::Dpy::end],

    );

  # catch already bound
  } elsif($has && !$inv) {

    errout(
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

  $Keys[$idex]->[1]=(defined $onTap)
    ? $onTap : $Keys[$idex]->[1];

  $Keys[$idex]->[2]=(defined $onHel)
    ? $onHel : $Keys[$idex]->[2];

  $Keys[$idex]->[3]=(defined $onRel)
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

  # fetch modules requesting keyboard access
  my $Ctl_Cache=$Lycon::Ctl::Cache;
  my $modules=$Ctl_Cache->{modules};

  # ^get keydata for all
  for my $mod(values %{$modules}) {

    my @names=array_keys($mod->{kbd});

    # check that reserved keys are mapped
    while(@names) {

      my $name=shift @names;
      my $id=Genks::KI($name);

      # set blank callbacks if reserved && unused
      if(!exists $KeyIDs{$id}) {

        define(

          $name,$id,

          $NULLSTR,
          $NULLSTR,
          $NULLSTR,

        );

      };

    };

  };

# ---   *   ---   *   ---
# register the events

  %Keys=@Keys;

  my @ntargs=Genks::pl_keymap(\@Keys,\%Keys);

  Lycon::keynt(@ntargs);

  # load callbacks
  ldkeys();

};

# ---   *   ---   *   ---
# load defined callbacks

sub ldkeys() {

my %shit=reverse %Keys;

  for(my $x=1;$x<@Keys;$x+=2) {

    my $name=$Keys[$x-1];
    my @ar=@{$Keys[$x]}[1..3];

    my $i=0;

# ---   *   ---   *   ---
# convert perl subs to closures
# ie, callable from C

    for my $ev(@ar) {

      if(is_coderef($ev)) {
        my $cev=$Lycon::FFI_Instance->closure($ev);
        $cev->sticky();

        Lycon::keycall($Keys{$name},$i,$cev);

      };

      $i++;

    };

  };

};

# ---   *   ---   *   ---
# gives current keyboard definitions and
# swaps them for a given modules's

sub swap_to($pkg=undef) {

  $pkg//=caller;

  my $modules=$Lycon::Ctl::Cache->{modules};

  my @keys=array_keys(
    $modules->{$pkg}->{kbd}

  );

  my @values=array_values(
    $modules->{$pkg}->{kbd}

  );

# ---   *   ---   *   ---

  my @saved_k_data=();

  while(@keys && @values) {

    my $name=shift @keys;
    my $calls=shift @values;

    my $id=Genks::KI($name);

    my $k_data=sv_by_id($id);

    redef(
      $k_data->[0],
      @$calls

    );

    push @saved_k_data,$k_data;

  };

# ---   *   ---   *   ---

  ldkeys();
  return @saved_k_data;

};

# ---   *   ---   *   ---

sub keytap($name) {
  return Lycon::keytap($Keys{$name})

};

sub keyhel($name) {
  return Lycon::keyhel($Keys{$name})

};

sub keyrel($name) {
  return Lycon::keyrel($Keys{$name})

};

# ---   *   ---   *   ---
1; # ret
