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
package genks;

  use v5.36.0;
  use strict;
  use warnings;

  use lib $ENV{'ARPATH'}.'/lib/';

  use style;
  use arstd;
  use shb7;

  use emit::c;

  use lang;

# ---   *   ---   *   ---
# info

  our $VERSION=v0.02.1;
  our $AUTHOR='IBN-3DILA';

# ---   *   ---   *   ---
# global storage

  my %CACHE=(
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

    };my ($ar_name,$X11_name)=split ' ',$line;
    if(!$ar_name) {$ar_name="$i";};

    $kbdlay{$ar_name}=$i;$i++;
    push @layi,$ar_name;

  };$CACHE{-LAYOUT_I}=\@layi;
  return \%kbdlay;

};$CACHE{-LAYOUT}=parse_kbdlay();

# arg=keyname
# Key Index, a simple shorthand
sub KI {
  my $key_name=shift;
  return $CACHE{-LAYOUT}->{$key_name};

};

# ---   *   ---   *   ---
# parse *.k file into a list

sub rdkfile {

  my $fpath=shift;
  my $pl_keys=shift;

  my $s=arstd::orc($fpath);
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

sub tifunc {
  my ($lc,$uc,$mr)=@_;

  for my $c($lc,$uc,$mr) {
    $c=sprintf "\\x%02X",ord($c);

  };

  my $s=<<"EOF"

  keycool();
  char table[4]="$lc$uc$mr";

  keyibs(table[
    (keyhel(K_LSHIFT))
   +(keyhel(K_RALT)<<1)

  ]);

EOF
; return $s;

};

# ---   *   ---   *   ---
# TODO: handle custom code on TI funcs

# in: path to key-charmap table
# generates text-input funcs
sub rdti {

  my $tifile=shift;
  if(!$tifile) {return ();};

  my @table=split "\n",arstd::orc($tifile);
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

    my $onDown=tifunc($lc,$uc,$mr);

    push @map,$fullname;
    push @map,[KI($name),
      $onDown,'',''

    ];

  };return @map;

};

# ---   *   ---   *   ---

# in: keymap array,file to text-input defs
# reads user-defined keymap
sub process_keymap($tifile,@KEYMAP) {

  $tifile=shb7::file($tifile);

# ---   *   ---   *   ---

  # walk through keymap
  for(my $i=0;$i<@KEYMAP;$i+=2) {

    # do keyname translation
    my $ar=$KEYMAP[$i+1];
    $ar->[0]=KI($ar->[0]);

    my $f=shb7::file($ar->[1]);

    # read callbacks from file
    if(-f $f) {
      pop @$ar;
      push @$ar,rdkfile($f);

    # or just ensure they are not undef
    } else {
      for(my $j=1;$j<4;$j++) {
        $ar->[$j]=(!$ar->[$j]) ? '' : $ar->[$j];

      };

    };

  };

# ---   *   ---   *   ---

  # save non text-input keycount
  $CACHE{-NON_TI}=int((@KEYMAP)/2);

  # read text-input config
  push @KEYMAP,rdti($tifile);
  $CACHE{-KEYMAP}=\@KEYMAP;

};

# ---   *   ---   *   ---

sub pl_keymap {

  my $aref=shift;
  my $href=shift;

  my $non_ti=shift;

#  $non_ti=(!defined $non_ti)
#    ? length(keys %$href)
#    : $non_ti
#    ;

  process_keymap($aref,'');
  my @KEYMAP=@{ $CACHE{-KEYMAP} };

# ---   *   ---   *   ---

  # get (used_indices:used_values)
  my @used_keys=();{

    for(my $i=1;$i<@KEYMAP;$i+=2) {
      push @used_keys,$KEYMAP[$i]->[0];

      # convert code string to code reference
      my @evs=@{$KEYMAP[$i]}[1..3];
      for my $ev(@evs) {

        if(!lang::is_coderef($ev)
        && length $ev

        ) {

          $ev=eval("sub {$ev;};");

        };
      };
    };

  };

# ---   *   ---   *   ---

  my @keylay=();

  my @lay=@{ $CACHE{-LAYOUT_I} };
  my $i=0;while(@lay) {
    my $kname=shift @lay;
    my $kcode=KI($kname);

    $keylay[$i]="\x00";

    # cant think of a smart way to do it
    for(my $j=0;$j<@used_keys;$j++) {

      if($used_keys[$j]==$kcode) {

        $keylay[$i]=sprintf "%c",$j+1;
        $href->{$KEYMAP[$j*2]}=$j;

        last;

      };

    };$i++;
  };

# ---   *   ---   *   ---

  return (

    0,

    (join '',@keylay),
    $#used_keys+1,
    $CACHE{-NON_TI}

  );

};

# ---   *   ---   *   ---

sub keymap_generator($fname) {

  my @KEYMAP=@{ $CACHE{-KEYMAP} };

  my %lists=(

    KEYMAP=>['static char',[]],
    K_COUNT=>['enum',[]],

    KEYLAY=>['static char',[]],

  );

# ---   *   ---   *   ---
# layout -> keymap lookup table

  # get (used_indices:used_values)
  my @used_keys=();{
    for(my $i=1;$i<@KEYMAP;$i+=2) {
      push @used_keys,$KEYMAP[$i]->[0];

    };

  };

# ---   *   ---   *   ---
# match layout indices to used ones

  my @lay=@{ $CACHE{-LAYOUT_I} };
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
    $CACHE{-NON_TI}."\n";

  for my $key(qw(KEYMAP K_COUNT KEYLAY)) {

    $result.=emit::c::datasec(

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

  my @KEYMAP=@{ $CACHE{-KEYMAP} };
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

      $defs.=emit::c::fnwrap(
        "K_$suff"."_FUNC_$name",
        $code,

        rtype=>'void',
        args=>'void',

      );

# ---   *   ---   *   ---

    };
  };

  $keyload_macro.="\n#endif\n";

  return $defs."\n".$keyload_macro;

};

# ---   *   ---   *   ---
1; # ret
