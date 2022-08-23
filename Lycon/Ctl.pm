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
# global state

  our $Cache={

    keysets=>[

      -COM=>[qw(escape ret space tab backspace del)],
      -NAV=>[qw(home end re av)],

      -CTL_R=>[qw(RShift RCtrl RAlt)],
      -CTL_L=>[qw(LShift LCtrl LAlt)],

      -MOV_A=>[qw(up left down right)],
      -MOV_B=>[qw(w a s d)],
      -MOV_C=>[qw(i j k l)],

    ],

    modules=>{},

  };

# ---   *   ---   *   ---
# register modules that do context switches

sub import {

  state $is_lycon_mod=qr{^Lycon\:\:}x;

  my $pkg=caller;

  # avoid initializing twice
  # do not register Lycon modules themselves
  if(($pkg=~ $is_lycon_mod)
  || exists $Cache->{modules}->{$pkg}) {return};

  # initialize
  my $ref=$Cache->{modules}->{$pkg}={

    kbd=>[],
    queue=>Queue->nit(),

  };

};

# ---   *   ---   *   ---
# lets Lycon know that a list of keys is in use

sub register_events(@args) {

  my $pkg=caller;
  my $modules=$Cache->{modules};

  my %ids=@{$Cache->{keysets}};

  my @keys=array_keys(\@args);
  my @keycalls=array_values(\@args);

  while(@keys && @keycalls) {

    my $key=shift @keys;
    my @calls=@{(shift @keycalls)};

    my $i=0;

    for my $id(@{$ids{$key}}) {

      push @{$modules->{$pkg}->{kbd}},$id=>[
        @calls[$i..$i+2]

      ];

      $i+=3;

    };

  };

};

# ---   *   ---   *   ---

sub get_module_queue() {

  my $pkg=caller;
  return $Cache->{modules}->{$pkg}->{queue};

};

# ---   *   ---   *   ---
1; # ret

