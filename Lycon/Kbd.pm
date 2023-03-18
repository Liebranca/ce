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
  use Avt::FFI;

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

  our $VERSION = v0.01.2;#a
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# ROM

  Readonly my $E_NOKEY=>
    q{%s <%s> is not bound};

  Readonly my $E_YESKEY=>
    q{%s <%s> is already bound};

# ---   *   ---   *   ---
# GBL

  my  @Keys   = ();
  our %Keys   = ();

  my  @SwKeys = ();
  my  %KeyIDs = ();

  our $Nited  = undef;

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

  $kvars,

  $onTap=undef,
  $onHel=undef,
  $onRel=undef,

) {

  haskey($key,0);
  hasid($id,0);

  $KeyIDs{$id}=$key;

  push @Keys,$key=>[
    $id,$kvars,$onTap,$onHel,$onRel

  ];

};

# ---   *   ---   *   ---
# swap out callbacks on this key

sub redef(

  $key,$kvars,

  $onTap=undef,
  $onHel=undef,
  $onRel=undef,

) {

  haskey($key,1);

  my $idex=($Keys{$key}*2)+1;

  $Keys[$idex]->[1]=$kvars;

  $Keys[$idex]->[2]=(defined $onTap)
    ? $onTap : $Keys[$idex]->[1];

  $Keys[$idex]->[3]=(defined $onHel)
    ? $onHel : $Keys[$idex]->[2];

  $Keys[$idex]->[4]=(defined $onRel)
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

sub sv_by_id($id) {

  my $key=key_by_id($id);
  my @def=svdef($key);

  return [$key,@def];

};

# ---   *   ---   *   ---
# store callbacks on this key

sub svdef($key) {

  haskey($key,1);

  my $idex=($Keys{$key}*2)+1;

  return (

    $Keys[$idex]->[1],
    $Keys[$idex]->[2],
    $Keys[$idex]->[3],
    $Keys[$idex]->[4],

  );

};

# ---   *   ---   *   ---
# ^restore saved callbacks

sub lddef($key,$kvars,@calls) {

  haskey($key,1);

  my $idex=($Keys{$key}*2)+1;

  $Keys[$idex]->[1]=$kvars;
  $Keys[$idex]->[2]=$calls[0];
  $Keys[$idex]->[3]=$calls[1];
  $Keys[$idex]->[4]=$calls[2];

};

# ---   *   ---   *   ---
# register events

sub nit() {

  return if $Nited;

  %Keys=@Keys;

  # fetch modules requesting keyboard access
  my $Ctl_Cache=$Lycon::Ctl::Cache;
  my $modules=$Ctl_Cache->{modules};

  # ^get keydata for all
  for my $mod(values %{$modules}) {

    my @names = array_keys($mod->{kbd});
    my @data  = array_values($mod->{kbd});

    # check that reserved keys are mapped
    while(@names && @data) {

      my $name  = shift @names;
      my $id    = Genks::KI($name);

      my $kvars = @{(shift @data)}[0];

      # set blank callbacks if reserved && unused
      if(! exists $KeyIDs{$id}) {

        define(

          $name,$id,

          $kvars,

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

  $Nited=1;

};

# ---   *   ---   *   ---
# template: map fn to key array

sub temple_walk($fn) {

  for(my $x=1;$x<@Keys;$x+=2) {

    my $name = $Keys[$x-1];
    my @ar   = @{$Keys[$x]}[2..4];

    my $i    = 0;

    for my $ev(@ar) {
      $fn->($name,$ev,$i);
      $i++;

    };

  };

};

# ---   *   ---   *   ---
# load defined callbacks

sub ldkeys() {

  # convert perl subs to closures
  # ie, callable from C
  state $fn=sub ($name,$ev,$i) {

    if(is_coderef($ev)) {

      my $cev=Avt::FFI->sticky($ev);

      Lycon::keycl($Keys{$name});
      Lycon::keycall($Keys{$name},$i,$cev);

    };

  };

  # ^map to whole key array
  temple_walk($fn);

};

# ---   *   ---   *   ---
# ^clears set keys

sub clkeys() {

  # assign no-op to callbacks
  state $cev = Avt::FFI->sticky($NOOP);
  state $fn  = sub ($name,$ev,$i) {
    Lycon::keycl($Keys{$name});
    Lycon::keycall($Keys{$name},$i,$cev);

  };

  # ^map to key array
  temple_walk($fn);

};

# ---   *   ---   *   ---
# gives current keyboard definitions and
# swaps them for a given modules's

sub swap_to($pkg=undef) {

  $pkg//=caller;

  my @out     = ();
  my @swap    = ();

  my $modules = $Lycon::Ctl::Cache->{modules};

  my @keys=array_keys(
    $modules->{$pkg}->{kbd}

  );

  my @calls=array_values(
    $modules->{$pkg}->{kbd}

  );

  # save old and get new
  while(@keys && @calls) {

    my $name = shift @keys;
    my $new  = shift @calls;

    my $old  = sv_by_id(Genks::KI($name));

    push @swap,[$name,@$new];
    push @out,$old;

  };

  # forget old config
  clkeys();

  # ^load new
  map {redef(@$ARG)} @swap;
  ldkeys();

  # give restore
  return @out;

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
