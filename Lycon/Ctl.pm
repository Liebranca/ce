#!/usr/bin/perl
# ---   *   ---   *   ---
# LYCON CONTROL
# Marks other modules for
# control switches
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,

# ---   *   ---   *   ---
# deps

package Lycon::Ctl;

  use v5.36.0;
  use strict;
  use warnings;

  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;
  use Arstd::Array;

  use Chk;
  use Queue;

  use lib $ENV{'ARPATH'}.'/lib/';

# ---   *   ---   *   ---
# info

  our $VERSION = v0.01.2;#a
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# global state

  our $Cache={
    modules => {},
    order   => [],

  };

  # sets special flags for certain keys
  # you'd seldom want to modify this, however
  # if you do, do so before register_events
  our $KVARS={

    RShift  => 1,
    RCtrl   => 1,
    RAlt    => 1,

    LShift  => 1,
    LCtrl   => 1,
    LAlt    => 1,

  };

# ---   *   ---   *   ---
# register modules that do context switches

sub import {

  state $is_lycon_mod=qr{^Lycon\:\:}x;

  my ($pkg)=caller;

  # avoid initializing twice
  # do not register Lycon modules themselves
  if(($pkg=~ $is_lycon_mod)
  || exists $Cache->{modules}->{$pkg}) {return};

  # initialize
  my $ref=$Cache->{modules}->{$pkg}={

    kbd => [],
    Q   => Queue->nit(),

  };

  # remember order in which
  # events are declared
  push @{$Cache->{order}},$pkg;

  # exporting by hand
  no strict 'refs';
    *{"$pkg\::get_module_queue"}=
      *get_module_queue;

  use strict 'refs';

};

# ---   *   ---   *   ---
# lets Lycon know that a list of keys is in use

sub register_events(@args) {

  my ($pkg)   = caller;
  my $modules = $Cache->{modules};

  my @keys    = array_keys(\@args);
  my @calls   = array_values(\@args);

  my $dst     = $modules->{$pkg}->{kbd};

  while(@keys && @calls) {

    my $key     = shift @keys;
    my $calls   = shift @calls;

    my $kvars   = $KVARS->{$key};
       $kvars //= 0;

    push @$dst,$key=>[$kvars,@$calls];

  };

};

# ---   *   ---   *   ---
# give pending ops

sub get_module_queue($pkg=undef) {
  $pkg //= caller;
  return $Cache->{modules}->{$pkg}->{Q};

};

# ---   *   ---   *   ---
# template: pass control to pkg

sub _call_temple($to,$epilogue) {

  return sub (@beq) {

    my @call = caller 1;

    my $pkg  = $call[0];
    my $ret  = "$pkg\::ctl_ret";
    my $loop = "$to\::ctl_loop";

    my $Q    = get_module_queue($to);

    $Q->add(\&$ret);
    $Q->skip(\&$loop,@beq);

    Lycon::Loop::transfer($to,$pkg);
    $epilogue->();

  };

};

# ---   *   ---   *   ---
# template: control hold

sub _loop_temple($at,$cond) {

  return sub (@beq) {

    my $Q    = get_module_queue($at);
    my $loop = "$at\::ctl_loop";

    $Q->skip(\&$loop,@beq) if $cond->();

    map {$ARG->()} @beq;

    my $draw = "$at\::draw";
       $draw = \&$draw;

    $draw->();

  };

};

# ---   *   ---   *   ---
# template: control return

sub _ret_temple($epilogue) {

  return sub (@args) {
    $epilogue->(@args);

  };

};

# ---   *   ---   *   ---
# template: select pkg to ctl_call

sub _switch_temple($prologue) {

  return sub ($pkg,@beq) {

    $prologue->($pkg);

    my $fn="$pkg\::ctl_call";
       $fn=\&$fn;

    $fn->(@beq);

  };

};

# ---   *   ---   *   ---
# ^generates control subs
# for caller module

sub register_xfers(%O) {

  # defaults
  $O{call}   //= $NOOP;
  $O{loop}   //= sub () {1};
  $O{ret}    //= $NOOP;
  $O{switch} //= $NOOP;


  my $pkg=caller;
  no strict 'refs';

  *{"$pkg\::ctl_call"}=
    _call_temple($pkg,$O{call});

  *{"$pkg\::ctl_loop"}=
    _loop_temple($pkg,$O{loop});

  *{"$pkg\::ctl_ret"}=
    _ret_temple($O{ret});

  *{"$pkg\::ctl_switch"}=
    _switch_temple($O{switch});

};

# ---   *   ---   *   ---
1; # ret

