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
  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;
  use Arstd::Array;

  use lib $ENV{'ARPATH'}.'/lib/';

  use Lycon::Kbd;

  use Lycon::Clk;
  use Lycon::Ctl;

# ---   *   ---   *   ---
# adds to your namespace

  use Exporter 'import';
  our @EXPORT=qw(
    defmain
    drawcmd

    graphics

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
# GBL

  my $Cache={

    logic_proc  => $NOOP,
    logic_args  => [],

    quit_proc   => \&never,

    gd          => 'ANSI',
    draw_buff   => '',

    stack       => [],

    busy        => 0,

    running     => [],

  };

# ---   *   ---   *   ---
# pushes draw commands to
# graphics driver

sub drawcmd(@slurp) {
  $Cache->{gd}->req(@slurp);

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
# pre-run routines

sub prologue(%O) {

  print $Cache->{gd}->encur(0)
  if $O{hide_cursor};

  print $Cache->{gd}->clear()
  if $O{clear_screen};

  print $Cache->{gd}->mvcur(0,0)
  if $O{reset_cursor};

};

# ---   *   ---   *   ---
# ^iv

sub epilogue(%O) {

  print $Cache->{gd}->clear()
  if $O{clear_screen};

  print $Cache->{gd}->encur(1)
  if $O{hide_cursor};

  print $Cache->{gd}->mvcur(0,0)
  if $O{reset_cursor};

};

# ---   *   ---   *   ---
# execute the main loop

sub run(%O) {

  # defaults
  $O{panic}        //= 60;
  $O{hide_cursor}  //= 1;
  $O{clear_screen} //= 1;
  $O{reset_cursor} //= 1;

  my $panic=$O{panic};
  delete $O{panic};


  # open
  prologue(%O);

  my $runid=int @{$Cache->{running}};
  $Cache->{running}->[$runid]=\%O;


  my %ctx    = (%O);
  my $dwbuff = $Cache->{gd}->{-buff};

  while(!$Cache->{quit_proc}->()) {

    $Cache->{busy}=Lycon::gtevcnt();

    # draw on update
    if(0 < @$dwbuff) {
      $Cache->{gd}->draw();

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


  # ^close and clear
  epilogue(%O);

  $Cache->{running}->[$runid]=undef;
  array_filter($Cache->{running});

};

# ---   *   ---   *   ---
# ^ensures epilogue runs

END {
  map {epilogue(%$ARG)} @{$Cache->{running}};

};

# ---   *   ---   *   ---
# modifies main loop

sub switch($logic,$args) {
  push @{$Cache->{stack}},get_state();
  set_logic($logic,$args);

};

# ---   *   ---   *   ---
# ^restores previous

sub restore($from) {

  my $draw  = pop @{$Cache->{stack}};
  my $args  = pop @{$Cache->{stack}};
  my $logic = pop @{$Cache->{stack}};

  set_logic($logic,$args);

  # restore keyboard state
  Lycon::Kbd::swap_to($from);

};

# ---   *   ---   *   ---
# skip first frame
# then clear keyboard state
#
# done so events dont overlap

sub fpause() {
  Lycon::tick($Cache->{busy});
  Lycon::kbdcl();

};

# ---   *   ---   *   ---
# transfers control from one module to another

sub transfer($to,$from,@args) {

  # alter keyboard state
  Lycon::Kbd::swap_to($to);
  fpause();


  # ^use module queue as logic routine
  my $Q=Lycon::Ctl::get_module_queue($to);

  switch(

    sub {

      # execute pending operations
      # walkback when done
      ($Q->pending())
        ? $Q->ex()
        : restore($from)
        ;

    },\@args

  );

  fpause();

};

# ---   *   ---   *   ---
1; # ret
