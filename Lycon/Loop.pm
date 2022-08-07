#!/usr/bin/perl
# ---   *   ---   *   ---
# LYCON LOOP
# A main with moving parts
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package Lycon::Loop;

  use v5.36.0;
  use strict;
  use warnings;

  use lib $ENV{'ARPATH'}.'/lib/sys/';
  use Style;

# ---   *   ---   *   ---
# lame fwd decl

  my %Loop=();

# ---   *   ---   *   ---
# shorthands

sub always {return 1;};
sub never {return 0;};

# ---   *   ---   *   ---
# flush out the draw buffer as-is

sub ascii {

  print $Loop{draw_buff};
  STDOUT->flush();

  $Loop{draw_buff}='';

};

# ---   *   ---   *   ---
# global state

  %Loop=(

    logic_proc=>\&lycon::nope,
    logic_args=>[],

    quit_proc=>\&never,

    draw_proc=>\&ascii,
    draw_buff=>'',

    busy=>0,

  );

# ---   *   ---   *   ---
# appends to draw buffer

sub dwbuff($s) {$s//=$NULLSTR;$Loop{draw_buff}.=$s};

# ---   *   ---   *   ---
# setters

sub set_logic($proc,$args) {
  $Loop{logic_proc}=$proc;
  $Loop{logic_args}=$args;

};

sub set_quit($proc) {$Loop{quit_proc}=$proc};
sub set_draw($proc) {$Loop{draw_proc}=$proc};

# ---   *   ---   *   ---
# gets functions currently used

sub get_state() {

  return (

    $Loop{logic_proc},
    $Loop{logic_args},
    $Loop{draw_proc};

  );

};

# ---   *   ---   *   ---
# execute the main loop

sub run() {

  while(!$Loop{quit_proc}->()) {

    $Loop{busy}=Lycon::gtevcnt();

    # draw on update
    if(0<length $Loop{draw_buff}) {
      $Loop{draw_proc}->()

    };

    Lycon::tick($Loop{busy});

    Lycon::keyrd();
    Lycon::keychk();

    # run logic
    $Loop{logic_proc}->(
      @{$Loop{logic_args}}

    );

  };

};

# ---   *   ---   *   ---
1; # ret
