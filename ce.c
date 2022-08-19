// ---   *   ---   *   ---
// CE
// champs' editor
//
// LIBRE SOFTWARE
// Licensed under GNU GPL3
// be a bro and inherit
//
// CONTRIBUTORS
// lyeb,
// ---   *   ---   *   ---

// deps

  #include <stddef.h>
  #include <stdlib.h>
  #include <string.h>
  #include <stdio.h>
  #include <unistd.h>

  #include "arstd.h"

  #include "clock.h"
  #include "display.h"

  #include "keymap.h"
  #include "keyboard.h"

// ---   *   ---   *   ---
// global state

  typedef struct {

    char ctty[16];

    struct {
      char lines[64][128];

    } file;

    int mode;

    char* fbuff;
    char** flines;

    size_t line_cnt;

  } STRUCT_CE;

  static STRUCT_CE CE={0};

// ---   *   ---   *   ---

  enum CE_MODES {
    CE_MTEXT,
    CE_MKEYS

  };

// ---   *   ---   *   ---
// text input

void pti(void) {

  int* cursor=gtcursor();
  char* ibuff=keyibl();

  if(*ibuff) {

    int x=cursor[0];
    int y=cursor[1];

    char* l=CE.file.lines[y];
    int len=strlen(l);

    if(len<x) {
      for(int i=len;i<x;i++) {
        if(!l[i]) {l[i]=' ';};

      };
    };

    l[x]=*ibuff;

    int mx=1+(9998*(*ibuff=='\n'));

    strcpy(gtrline(y),l);
    cursormv(mx,0);

  };

  *ibuff^=*ibuff;

};

// ---   *   ---   *   ---
// file handling

void dumpf(void) {

  FILE* f=fopen("./test","w+");

  for(int y=0;y<64;y++) {

    char* line=CE.file.lines[y];

    if(*line) {
      fwrite(line,strlen(line),sizeof(char),f);

    };

  };

  fclose(f);

};

// ---   *   ---   *   ---
// load these in last

  #include "keycalls.h"

// ---   *   ---   *   ---

void main(int argc,char** argv) {

  do {

    if(!strcmp(*argv,"-k")) {
      CE.mode=CE_MKEYS;

    };

    argv++;
    argc--;

  } while(argc);

  // open display
  dpynt(STDOUT_FILENO);

  // open input handler
  if(KEYNT(STDIN_FILENO)) {
    fprintf(stderr,"Aborted\n");
    exit(-1);

  };

// ---   *   ---   *   ---
// init the program clock

  clknt(
    0x6000,

    L"\x01A9\x01AA\x01AB\x01AC"
    L"\x01AD\x01AE\x01AF\x01B0",

    8

  );

  // populate input callback arrays
  K_FUNCS_LOAD;

// ---   *   ---   *   ---
// looparino

  int* sc_dim=gtwsz();
  int PANIC_TIMER=1600;

  do {

    // render last frame
    dpyrend();

    // update the draw clock and tick
    sprintf(

      gtrline(sc_dim[1]-1),
      "%lc",clkdr()

    );

    tick(gtevcnt());

    // run event loop
    keyrd();
    keychk();

    pti();

// ---   *   ---   *   ---
// cleanup

  } while(PANIC_TIMER--);

  free(CE.flines);
  free(CE.fbuff);

  dpycl();
  exit(0);

};

// ---   *   ---   *   ---
