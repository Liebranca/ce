#!/usr/bin/perl
#
# This is a placeholder ;>
#
# ---   *   ---   *   ---

# deps
package Lycon::Dpy;

  use v5.36.0;
  use strict;
  use warnings;

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
