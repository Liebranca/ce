#!/usr/bin/perl
# ---   *   ---   *   ---
# GENKS
# generates tables for
# key lookups, and such

# LIBRE SOFTWARE
# Licensed under GNU GPL3
# be a bro and inherit

# CONTRIBUTORS
# lyeb,
# ---   *   ---   *   ---

# deps
package Genks;

  use v5.36.0;
  use strict;
  use warnings;

  use English qw(-no_match_vars);

  use lib $ENV{'ARPATH'}.'/lib/sys/';

  use Style;

  use Arstd::Array;
  use Arstd::IO;

  use Chk;
  use Shb7;

  use lib $ENV{'ARPATH'}.'/lib/';

  use Emit::C;

# ---   *   ---   *   ---
# info

  our $VERSION=v0.02.1;
  our $AUTHOR='IBN-3DILA';

# ---   *   ---   *   ---
# global storage

  my %Cache=(
    -LAYOUT   => 0,
    -LAYOUT_I => 0,

    -KEYMAP   => undef,
    -NON_TI   => 0,

  );

# ---   *   ---   *   ---

# magic
sub parse_kbdlay {

  my $f=$ENV{'ARPATH'}.'/ce/kbdlay';

  my @lines=split "\n",`cat $f`;
  my %kbdlay;my $i=0;
  my @layi=();

  while(@lines) {

    my $line=shift @lines;
    if(!$line || (index $line,'#')==0) {
      next;

    };

    if($line eq 'NON') {
      $line.="$i";
      $line.=" $line";

    };

    my ($ar_name,$X11_name)=split ' ',$line;
    if(!$ar_name) {$ar_name="$i"};

    $kbdlay{$ar_name}=$i;$i++;
    push @layi,$ar_name;

  };

  $Cache{-LAYOUT_I}=\@layi;
  return \%kbdlay;

};

$Cache{-LAYOUT}=parse_kbdlay();

# ---   *   ---   *   ---
# Key Index, a simple shorthand

sub KI($key_name) {
  return $Cache{-LAYOUT}->{$key_name};

};

# ---   *   ---   *   ---
# parse *.k file into a list

sub rdkfile {

  my $fpath=shift;
  my $pl_keys=shift;

  my $s=orc($fpath);
  my $tap=(split "onTap\n",$s)[1];
  $tap=(split "onHel\n",$tap)[0];

  my $hel=(split "onHel\n",$s)[1];
  $hel=(split "onRel\n",$hel)[0];

  my $rel=(split "onRel\n",$s)[1];

  for my $ev ($tap,$hel,$rel) {
    if((index $ev,'None')>-1) {$ev='';};

  };

  return ($tap,$hel,$rel);

};

# ---   *   ---   *   ---
# read glyph table

sub tifunc($pl,$lc,$uc,$mr) {

  my $s=$NULLSTR;

# generate pl sub
if($pl) {

  for my $c($lc,$uc,$mr) {
    $c=ord($c);

  };

  $s=sub {

    Lycon::keycool();
    my @ar=($lc,$uc,$mr);

    Lycon::keyibs($ar[
      (Lycon::keyhel($Lycon::Kbd::Keys{LShift}))
    + (Lycon::keyhel($Lycon::Kbd::Keys{RAlt})<<1)

    ]);

  };

# generate c func
} else {

  for my $c($lc,$uc,$mr) {
    $c=sprintf "\\x%02X",ord($c);

  };

  $s=<<"EOF"

  keycool();
  char table[4]="$lc$uc$mr";

  keyibs(table[
    (keyhel(K_LSHIFT))
   +(keyhel(K_RALT)<<1)

  ]);

EOF

;};return $s;

};

# ---   *   ---   *   ---
# TODO: handle custom code on TI funcs

# in: path to key-charmap table
# generates text-input funcs
sub rdti($tifile,$pl=0) {

  if(!$tifile) {return ();};

  my @table=split "\n",orc($tifile);
  my @map=();

  while(@table) {
    my $line=shift @table;
    if(!$line) {next;};

    my (
      $name,
      $lc,$uc,$mr

    )=split ' ',$line;

# ---   *   ---   *   ---

    my $fullname='TI'.( uc $name );
    if($name eq 'space') {
      $lc=$uc=$mr=' ';

    };

    my $onDown=tifunc($pl,$lc,$uc,$mr);

    push @map,$fullname;
    push @map,[KI($name),0,
      $onDown,'',''

    ];

  };

  return @map;

};

# ---   *   ---   *   ---
# reads user-defined keymap

sub process_keymap($tifile,$pl,@KEYMAP) {

  if(length $tifile) {
    $tifile=Shb7::file($tifile);

  };

# ---   *   ---   *   ---

  my @names=array_keys(\@KEYMAP);
  my @values=array_values(\@KEYMAP);

  # walk through keymap
  while(@names && @values) {

    my $name=shift @names;
    my $ar=shift @values;

    # attempt keyname translation
    my $t=KI($ar->[0]);
    $ar->[0]=$t if defined $t;

    my $f=Shb7::file($ar->[2]);

    # read callbacks from file
    if(-f $f) {
      pop @$ar;
      push @$ar,rdkfile($f);

    # or just ensure they are not undef
    } else {
      for(my $j=2;$j<5;$j++) {
        $ar->[$j]=(!$ar->[$j]) ? '' : $ar->[$j];

      };

    };

  };

# ---   *   ---   *   ---

  # save non text-input keycount
  $Cache{-NON_TI}=int((@KEYMAP)/2);

  # read text-input config
  push @KEYMAP,rdti($tifile,$pl);
  $Cache{-KEYMAP}=\@KEYMAP;

};

# ---   *   ---   *   ---

sub pl_keymap($src,$dst,$tifile=$NULLSTR) {

  process_keymap('ce/keys/ti',1,@$src);
  my @KEYMAP=@{ $Cache{-KEYMAP} };

  @$src=@KEYMAP;

# ---   *   ---   *   ---

  # get (used_indices:used_values)
  # also collect flags

  my @keyvars=();
  my @used_keys=();{

    for(my $i=1;$i<@KEYMAP;$i+=2) {

      push @used_keys,$KEYMAP[$i]->[0];
      push @keyvars,$KEYMAP[$i]->[1];

      # convert code string to code reference
      my @evs=@{$KEYMAP[$i]}[2..4];
      for my $ev(@evs) {

        if(!is_coderef($ev)
        && length $ev

        ) {

          $ev=eval("sub {$ev;};");

        };

      };

    };

  };

# ---   *   ---   *   ---

  my @keylay=();
  my @lay=@{ $Cache{-LAYOUT_I} };

  my $i=0;

  while(@lay) {
    my $kname=shift @lay;
    my $kcode=KI($kname);

    $keylay[$i]="\x00";

    # cant think of a smart way to do it
    for(my $j=0;$j<@used_keys;$j++) {

      if($used_keys[$j]==$kcode) {

        $keylay[$i]=sprintf "%c",$j+1;
        $dst->{$KEYMAP[$j*2]}=$j;

        last;

      };

    };

    $i++;

  };

# ---   *   ---   *   ---

  return (

    0,

    (join '',@keylay),

    \@keyvars,

    $#used_keys+1,
    $Cache{-NON_TI}

  );

};

# ---   *   ---   *   ---

sub keymap_generator($fname) {

  my @KEYMAP=@{ $Cache{-KEYMAP} };

  my %lists=(

    KEYMAP=>['static char',[]],
    K_COUNT=>['enum',[]],

    KEYLAY=>['static char',[]],
    KEYVARS=>['static int',[]],

  );

# ---   *   ---   *   ---
# layout -> keymap lookup table

  # get (used_indices:used_values)
  # collect flags

  my @used_keys=();{

    my $items=$lists{KEYVARS}->[1];
    for(my $i=1;$i<@KEYMAP;$i+=2) {
      push @used_keys,$KEYMAP[$i]->[0];
      push @$items,$KEYMAP[$i]->[1];

    };

  };

# ---   *   ---   *   ---
# match layout indices to used ones

  my @lay=@{ $Cache{-LAYOUT_I} };
  my $items=$lists{KEYLAY}->[1];

  while(@lay) {

    my $kname=shift @lay;
    my $kcode=KI($kname);

    push @$items,0;

    # cant think of a smart way to do it
    for(my $j=0;$j<@used_keys;$j++) {

      if($used_keys[$j]==$kcode) {
        $items->[-1]=$j+1;
        last;

      };

    };

  };

# ---   *   ---   *   ---
# iter through the map

  for(my $i=0;$i<@KEYMAP;$i+=2) {

    my $name=$KEYMAP[$i+0];
    my $data=$KEYMAP[$i+1];

    # unpack array reference
    my (
      $kcode,
      $kvar,
      $onTap,
      $onHel,
      $onRel,

    )=@{ $data };

# ---   *   ---   *   ---
# populate lists

    $items=$lists{KEYMAP}->[1];
    push @$items,$kcode;

    $items=$lists{K_COUNT}->[1];
    push @$items,"K_$name";

  };

# ---   *   ---   *   ---

  my $result=q{#define NON_TI }.
    $Cache{-NON_TI}."\n";

  for my $key(qw(

    KEYMAP
    K_COUNT
    KEYLAY
    KEYVARS

  )) {

    $result.=Emit::C->datasec(

      $key,

      $lists{$key}->[0],
      @{$lists{$key}->[1]}

    );

  };

  return $result;

};

# ---   *   ---   *   ---

# auxiliary file
sub keycalls_generator($fname) {

  my @KEYMAP=@{ $Cache{-KEYMAP} };
  my $result=$NULLSTR;
  my $defs=$NULLSTR;

  my $keyload_macro="#define K_FUNCS_LOAD \\\n";

  # iter through the map
  for(my $i=0;$i<@KEYMAP;$i+=2) {

    my $name=$KEYMAP[$i+0];
    my $data=$KEYMAP[$i+1];

# ---   *   ---   *   ---
# unpack the key struct

    my (

      $kcode,
      $kvar,

      $onTap,
      $onHel,
      $onRel,

    )=@{ $data };

    my @helper=(
      $onTap,'TAP',
      $onHel,'HEL',
      $onRel,'REL',

    );

# ---   *   ---   *   ---
# look at each key event

    my $j=0;
    while(@helper) {

      my $code=shift @helper;
      my $suff=shift @helper;

      # populate callback arrays
      my $funcname=(!$code)
        ? "nope"
        : "\&K_$suff"."_FUNC_$name"
        ;

      $keyload_macro.=
        "keycall(K_$name,".
        "$j,$funcname);\\\n";

      $j++;

# ---   *   ---   *   ---
# skip empty or make definition

      if(!$code) {next};

      $defs.=Emit::C->fnwrap(
        "K_$suff"."_FUNC_$name",
        $code,

        rtype=>'void',
        args=>'void',

      );

# ---   *   ---   *   ---

    };
  };

  $keyload_macro.="\n";
  return $defs."\n".$keyload_macro;

};

# ---   *   ---   *   ---
1; # ret
