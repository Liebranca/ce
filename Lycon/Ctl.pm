#!/usr/bin/perl
# ---   *   ---   *   ---
# LYCON CONTROL
# Handles control switches
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

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Chk;
  use Queue;

  use lib $ENV{'ARPATH'}.'/lib/';


my %Ctl=(

  stack=>[],

  base_keys=>[

    -EXIT=>['escape'],
    -ACCEPT=>['ret'],
    -ACCEL=>['space'],

    -MOV_A=>['up','down','right','left'],
    -MOV_B=>['w','a','s','d'],
    -MOV_C=>['i','k','j','l'],

  ],

  modules=>{},

);

# ---   *   ---   *   ---
# register modules that do context switches

sub import {

  state $is_lycon_mod=qr{^Lycon\:\:}x;

  my $pkg=caller;
  my @keys=@_;

  # avoid initializing twice
  # do not register Lycon modules themselves
  if(($pkg=~ $is_lycon_mod)
  || exists $Ctl{modules}->{$pkg}) {return};

# ---   *   ---   *   ---
# initialize

  my $ref=$Ctl{modules}->{$pkg}={

    kbd=>[],
    queue=>Queue->nit(),

  };

# ---   *   ---   *   ---
# iter: get set of callbacks for
# each key reserved by module

  while(@keys) {
    my $key=shift @keys;
    my $calls=shift @keys;

    for my $call(@$calls) {
      if(!is_coderef($call)) {
        $call=\&NOOP;

      };
    };

    $ref->{kbd}->{$key}=$calls;

  };

};

# ---   *   ---   *   ---
# ^ get keys used by module

sub used_keys($pkg=undef) {

  $pkg//=caller;

  my @ids=();

  my @values=Arstd::array_values(
    $Ctl{base_keys}

  );

  my @keys=Arstd::array_keys(
    $Ctl{modules}->{$pkg}->{kbd}

  );

  for my $key(@keys) {
    push @ids,grep {$ARG eq $key} ;

  };

  return \@ids;

};

# ---   *   ---   *   ---
# ^ get all keys used by ALL modules

sub all_used_keys {

  my $ref=$Ctl{modules};
  my %keys=();

  for my $pkg(keys %$ref) {

    my $ids=used_keys($pkg);
    for my $id(@$ids) {
      $keys{$id}="-".(uc $id);

    };

  };

  return \%keys;

};

# ---   *   ---   *   ---

sub get_module_queue() {

  my $pkg=caller;
  return $Ctl{modules}->{$pkg}->{queue};

};

# ---   *   ---   *   ---
# modifies main loop

sub switch($logic,$args,$draw) {

  push @{$Ctl{stack}},Lycon::Loop::get_state();

  Lycon::Loop::set_logic($logic);
  Lycon::Loop::set_draw($draw);

};

# ---   *   ---   *   ---
# ^restores previous

sub ret() {

  my $draw=pop @{$Ctl{stack}};
  my $args=pop @{$Ctl{stack}};
  my $logic=pop @{$Ctl{stack}};

  Lycon::Loop::set_logic($logic,$args);
  Lycon::Loop::set_draw($draw);

};

# ---   *   ---   *   ---
# transfers control from one module to another

sub transfer() {

  my $pkg=caller;

  my $keys=$Ctl{modules}->{$pkg}->{kbd};
  my $queue=Ctl{modules}->{$pkg}->{queue};

# ---   *   ---   *   ---

  my @saved_k_data=();

  for my $key(keys %$keys) {

    my $ids=$Ctl{base_keys}->{$key};
    my $calls=$keys->{$key};

    my $i=0;

# ---   *   ---   *   ---

    for my $id(@$ids) {
      my $k_data=Lycon::Kbd::sv_by_id($id);
      my @calls=(@$calls)[$i..$i+2];

      $i+=3;

      Lycon::Kbd::redef(
        $k_data->[0],
        @calls

      );

      push @saved_k_data,$k_data;

    };

# ---   *   ---   *   ---

  };

  Lycon::Kbd::ldkeys();

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
