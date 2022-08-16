#!/usr/bin/perl
# ---   *   ---   *   ---
# LYCON DPY
# What sits between loop
# and whatever handles drawing
#
# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit
#
# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package Lycon::Dpy;

  use v5.36.0;
  use strict;
  use warnings;

  use English qw(-no_match_vars);

# ---   *   ---   *   ---

sub beg {
  print "\e[0m\e[2J\e[0H\e[?25l";
  STDOUT->flush();

};

sub end {
  print "\e[0m\e[2J\e[0H\e[?25h";
  STDOUT->flush();

};

# ---   *   ---   *   ---
1; # ret
