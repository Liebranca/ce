#!/usr/bin/perl

# ---   *   ---   *   ---
# deps

  use v5.36.0;
  use strict;
  use warnings;

  use lib $ENV{'ARPATH'}.'/lib/sys/';
  use Shb7;

  use lib $ENV{'ARPATH'}.'/lib/';
  use Avt;

# ---   *   ---   *   ---

my $root=Shb7::set_root($ENV{'ARPATH'});

# ---   *   ---   *   ---

Avt::set_config(

  name=>'ce',
  scan=>'-x keys',

  build=>'x:ce',

  xcpy=>[qw(wpid)],
  xprt=>[qw(keyboard.h clock.h arstd.h)],

  gens=>{

    'chartab.h'=>[qw(chartab)],
    'keymap.h'=>[qw(keymap Genks.pm %.k)],

  },

  libs=>[qw(X11)],

# ---   *   ---   *   ---

  post_build=>q(

    use Emit::Std;
    use Emit::Perl;

    Emit::Std::outf(

      'Perl','lib/Lycon.pm',

      author=>'IBN-3DILA',
      include=>[qw(Avt::FFI)],

      body=>\&Emit::Perl::shwlbind,
      args=>['Lycon',['ce']],

    );

  ),

);

# ---   *   ---   *   ---

Avt::scan();
Avt::config();
Avt::make();

# ---   *   ---   *   ---
1; # ret
