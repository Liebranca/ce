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

  use Arstd::Array;

  use Chk;
  use Queue;

  use lib $ENV{'ARPATH'}.'/lib/';

# ---   *   ---   *   ---
# info

  our $VERSION = v0.01.0;#a
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# global state

  our $Cache={
    modules=>{},

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

    kbd=>[],
    queue=>Queue->nit(),

  };

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

sub get_module_queue() {

  my $pkg=caller;
  return $Cache->{modules}->{$pkg}->{queue};

};

# ---   *   ---   *   ---
1; # ret

