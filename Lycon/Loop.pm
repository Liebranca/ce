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
  use Arstd;

  use lib $ENV{'ARPATH'}.'/lib/';

  use Lycon::Kbd;
  use Lycon::Ctl;

# ---   *   ---   *   ---
# lame fwd decl

  my $Cache={};

# ---   *   ---   *   ---
# shorthands

sub always {return 1;};
sub never {return 0;};

# ---   *   ---   *   ---
# flush out the draw buffer as-is

sub ascii {

  print $Cache->{draw_buff};
  STDOUT->flush();

  $Cache->{draw_buff}='';

};

# ---   *   ---   *   ---
# global state

  $Cache={

    logic_proc=>$NOOP,
    logic_args=>[],

    quit_proc=>\&never,

    draw_proc=>\&ascii,
    draw_buff=>'',

    stack=>[],

    busy=>0,

  };

# ---   *   ---   *   ---
# appends to draw buffer

sub dwbuff($s) {
  $s//=$NULLSTR;
  $Cache->{draw_buff}.=$s

};

# ---   *   ---   *   ---
# setters

sub set_logic($proc,$args) {
  $Cache->{logic_proc}=$proc;
  $Cache->{logic_args}=$args;

};

sub set_quit($proc) {$Cache->{quit_proc}=$proc};
sub set_draw($proc) {$Cache->{draw_proc}=$proc};

# ---   *   ---   *   ---
# gets functions currently used

sub get_state() {

  return (

    $Cache->{logic_proc},
    $Cache->{logic_args},
    $Cache->{draw_proc},

  );

};

# ---   *   ---   *   ---
# execute the main loop

sub run() {

  my $panic=600;
  while(!$Cache->{quit_proc}->()) {

    $Cache->{busy}=Lycon::gtevcnt();

    # draw on update
    if(0<length $Cache->{draw_buff}) {
      $Cache->{draw_proc}->()

    };

    Lycon::tick($Cache->{busy});

    Lycon::keyrd();
    Lycon::keychk();

    # run logic
    $Cache->{logic_proc}->(
      @{$Cache->{logic_args}}

    );

    $panic--;
    if(!$panic) {last};

  };

};

# ---   *   ---   *   ---
# modifies main loop

sub switch($logic,$args,$draw) {

  push @{$Cache->{stack}},get_state();

  set_logic($logic,$args);
  set_draw($draw);

};

# ---   *   ---   *   ---
# ^restores previous

sub ret() {

  my $draw=pop @{$Cache->{stack}};
  my $args=pop @{$Cache->{stack}};
  my $logic=pop @{$Cache->{stack}};

  set_logic($logic,$args);
  set_draw($draw);

};

# ---   *   ---   *   ---
# transfers control from one module to another

sub transfer() {

  my $pkg=caller;
  my @saved_k_data=Lycon::Kbd::swap_to($pkg);

  my $modules=$Lycon::Ctl::Cache->{modules};
  my $queue=$modules->{$pkg}->{queue};

  # TODO: pass draw,logic && logic_args
  # for each registered module

  switch(

    sub {

      # execute pending operations
      if($queue->pending()) {
        $queue->ex();

      # restore previous state
      } else {

        ret();

        for my $k_data(@saved_k_data) {
          Lycon::Kbd::lddef(@$k_data);

        };

      };

    },

    [],\&Lycon::Loop::ascii,

  );

};

# ---   *   ---   *   ---
1; # ret
