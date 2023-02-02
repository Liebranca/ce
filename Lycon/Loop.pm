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

  use Readonly;
  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;
  use Arstd;

  use lib $ENV{'ARPATH'}.'/lib/';

  use Lycon::Kbd;

  use Lycon::Clk;
  use Lycon::Ctl;

# ---   *   ---   *   ---
# adds to your namespace

  use Exporter 'import';
  our @EXPORT=qw(
    defmain

  );

# ---   *   ---   *   ---
# info

  our $VERSION = v0.01.0;#a
  our $AUTHOR  = 'IBN-3DILA';

# ---   *   ---   *   ---
# shorthands

sub always {return 1;};
sub never {return 0;};

# ---   *   ---   *   ---
# ROM

  Readonly our $DEFAULTS=>{

    logic    => {
      args=>[],
      proc=>$NOOP

    },

    quit     => \&never,
    graphics => 'ANSI',

    clock    => {},

  };

# ---   *   ---   *   ---
# global state

  my $Cache={

    logic_proc=>$NOOP,
    logic_args=>[],

    quit_proc=>\&never,

    gd=>'ANSI',
    draw_buff=>'',

    stack=>[],

    busy=>0,

  };

# ---   *   ---   *   ---
# appends to draw buffer

sub dwbuff($s) {
  $s//=$NULLSTR;
  $Cache->{gd}->{-buff}.=$s;

};

# ---   *   ---   *   ---
# setters

sub set_logic($proc,$args) {
  $Cache->{logic_proc}=$proc;
  $Cache->{logic_args}=$args;

};

sub set_quit($proc) {$Cache->{quit_proc}=$proc};

sub graphics($driver_name=undef) {

  if(defined $driver_name) {
    $Cache->{gd}=eval(
      "GF\::Mode\::$driver_name->canvas()"

    );

  };

  return $Cache->{gd};

};

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
# used to initialize/reset main

sub defmain(%O) {

  my ($pkg)=caller;

  # set defaults
  for my $key(keys %$DEFAULTS) {
    $O{$key} //= $DEFAULTS->{$key};

  };

  set_logic(
    $O{logic}->{proc},
    $O{logic}->{args},

  );

  set_quit($O{quit});
  graphics($O{graphics});

  Lycon::Kbd::nit();
  Lycon::Clk::nit(%{$O{clock}});

  my $main=sub (%vars) {
    Lycon::Kbd::swap_to($pkg);
    run(%vars);

  };

  return $main;

};

# ---   *   ---   *   ---
# execute the main loop

sub run(%O) {

  # defaults
  $O{panic}//=60;

  my $panic=$O{panic};
  delete $O{panic};

  my %ctx=(%O);
  my $dwbuff=\$Cache->{gd}->{-buff};

  while(!$Cache->{quit_proc}->()) {

    $Cache->{busy}=Lycon::gtevcnt();

    # draw on update
    if(0<length $$dwbuff) {

      $Cache->{gd}->draw(%ctx);

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
