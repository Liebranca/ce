#!/usr/bin/perl
# ---   *   ---   *   ---
# LYCON CLOCK
# Wrappers around the program
# clock initializer...
#
# Not much else going on ;>
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package Lycon::Clk;

  use v5.36.0;
  use strict;
  use warnings;

  use lib $ENV{'ARPATH'}.'/lib/';
  use Lycon;

# ---   *   ---   *   ---
# constructor

sub nit(%O) {

  # defaults
  $O{flen}//=0x6000;
  $O{vsz}//=8;

  $O{vis}//=

    "\x{01A9}\x{01AA}\x{01AB}\x{01AC}".
    "\x{01AD}\x{01AE}\x{01AF}\x{01B0}"

  ;

  Lycon::clknt(
    $O{flen},
    $O{vis},
    $O{vsz}

  );

};

# ---   *   ---   *   ---
1; # ret
