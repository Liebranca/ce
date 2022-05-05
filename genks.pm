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

  use strict;
  use warnings;

  use lib $ENV{'ARPATH'}.'/lib/';

  use lang;
  use avt;

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

  if(!(-e $fpath)) {
    print "Can't find $fpath";
    exit;

  };my $s=`cat $fpath`;
  my $tap=(split "onTap\n",$s)[1];
  $tap=(split "onHel\n",$tap)[0];

  my $hel=(split "onHel\n",$s)[1];
  $hel=(split "onRel\n",$hel)[0];

  my $rel=(split "onRel\n",$s)[1];

  for my $ev ($tap,$hel,$rel) {
    if((index $ev,'None')>-1) {$ev='';};

  };return ($tap,$hel,$rel);

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

  my @table=split "\n",`cat $tifile`;
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
sub process_keymap {

  my @KEYMAP=@{ $_[0] };shift;
  my $tifile=shift;

# ---   *   ---   *   ---

  # walk through keymap
  for(my $i=0;$i<@KEYMAP;$i+=2) {

    # do keyname translation
    my $ar=$KEYMAP[$i+1];
    $ar->[0]=KI($ar->[0]);

    # read callbacks from file
    if(-e $ar->[1]) {
      my $kfile=pop @$ar;
      push @$ar,rdkfile($kfile);

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

        if(!lang::is_code($ev)
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

sub keymap_generator {

  my $FH=shift;
  my @KEYMAP=@{ $CACHE{-KEYMAP} };

  my @lists=();{

    my $item;

    # KEYMAP[key_name]==scancode
    # we don't use this, nice to have maybe?
    $item=avt::clist([0,'arr:char','KEYMAP','']);

    push @lists,$item;

    $item=avt::clist([0,'enum:K_COUNT','','']);
    push @lists,$item;

  };

# ---   *   ---   *   ---
# layout -> keymap lookup table

  my $CODE_TO_KEY='';{

    # get (used_indices:used_values)
    my @used_keys=();{
      for(my $i=1;$i<@KEYMAP;$i+=2) {
        push @used_keys,$KEYMAP[$i]->[0];

      };
    };my $list=avt::clist(
      [0,'arr:char','KEYLAY','']

    );

# ---   *   ---   *   ---

    # match layout indices to used ones
    my @lay=@{ $CACHE{-LAYOUT_I} };
    my $i=0;while(@lay) {
      my $kname=shift @lay;
      my $kcode=KI($kname);

      $list->[2]=0;

      # cant think of a smart way to do it
      for(my $j=0;$j<@used_keys;$j++) {

        if($used_keys[$j]==$kcode) {
          $list->[2]=$j+1;last;

        };
      };

      $list=avt::clist($list);

    };$list->[0]++;

    $list=avt::clist($list);
    $CODE_TO_KEY=$list->[3];

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
    { my @items=($kcode,"K_$name");
      for(my $j=0;$j<@lists;$j++) {
        $lists[$j]->[2]=$items[$j];
        $lists[$j]=avt::clist($lists[$j]);

      };
    };

  };

# ---   *   ---   *   ---

  my $result=''.
    "#define NON_TI $CACHE{-NON_TI}\n".
    $CODE_TO_KEY;

  # close lists
  for(my $j=0;$j<@lists;$j++) {
    $lists[$j]->[0]++;
    $lists[$j]=avt::clist($lists[$j]);

    $result.=$lists[$j]->[3];

  };

  # write it all to file
  print $FH $result;

};

# ---   *   ---   *   ---

# auxiliary file
sub keycalls_generator {

  my $FH=shift;
  my @KEYMAP=@{ $CACHE{-KEYMAP} };

  my $result='';
  my $evtable="#ifndef K_FUNCS_LOAD\n".
    "#define K_FUNCS_LOAD \\\n";

  my $evfuncs=['void:void','','',''];

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

    # go through the code
    { my @helper=(
        $onTap,'TAP',
        $onHel,'HEL',
        $onRel,'REL',

      );my $j=0;while(@helper) {
        my $code=shift @helper;
        my $suff=shift @helper;

        # populate callback arrays
        my $funcname=(!$code)
          ? "nope"
          : "\&K_$suff"."_FUNC_$name"
          ;

        $evtable.="keycall(K_$name,$j,$funcname);\\\n";
        $j++;

# ---   *   ---   *   ---

        # skip empty or make definition
        if(!$code) {next;};

        $evfuncs->[1]="K_$suff"."_FUNC_$name";
        $evfuncs->[2]=$code;

        $evfuncs=avt::cfunc($evfuncs);


      };
    };
  };

# ---   *   ---   *   ---

  $result.=( $evfuncs->[3] ).$evtable."\n#endif\n";
  print $FH $result;

};

# ---   *   ---   *   ---
1; # ret
