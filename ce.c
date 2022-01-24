// ---   *   ---   *   ---
// CE
// champs' editor

// LIBRE SOFTWARE
// Licensed under GNU GPL3
// be a bro and inherit

// CONTRIBUTORS
// lyeb,
// ---   *   ---   *   ---

// deps

  #include <stddef.h>
  #include <stdlib.h>
  #include <string.h>
  #include <stdio.h>

  #include "arstd.h"

  #include "clock.h"
  #include "display.h"
  #include "keyboard.h"

// ---   *   ---   *   ---
// global state

  typedef struct {

    char ctty[16];

    struct {
      char lines[64][128];

    } file;

    int mode;

  } STRUCT_CE;static STRUCT_CE CE={0};

// ---   *   ---   *   ---

  enum CE_MODES {
    CE_MTEXT,
    CE_MKEYS

  };

// ---   *   ---   *   ---
/*
  // text input
  if(CE.ti) {

    CE.file.lines[CE.cursor.y][CE.cursor.x]=CE.ti;

    strcpy(
      CE.render.lines[CE.cursor.y],
      CE.file.lines[CE.cursor.y]

    );

    CE.ti=0x00;

    CE.cursor.x++;
    if(CE.cursor.x>=(CE.wsz.ws_col-1)) {
      CE.cursor.x=0;
      CE.cursor.y+=CE.cursor.y<(CE.wsz.ws_row-1);

    };
  };
*/
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

void main(int argc,char** argv) {

  do {
    if(!strcmp(*argv,"-k")) {
      CE.mode=CE_MKEYS;

    };argv++;argc--;

  } while(argc);

  // open display
  dpynt(STDOUT_FILENO);

  // open input handler  
  keynt(STDIN_FILENO);

  // init the program clock
  clknt(
    0x6000,

    L"\x01A9\x01AA\x01AB\x01AC"
    L"\x01AD\x01AE\x01AF\x01B0",

    8

  );

// ---   *   ---   *   ---

  int* sc_dim=gtwsz();

  // looparino
  int PANIC_TIMER=60;do {

    // render last frame
    brend(CE.dpy);

    // update the draw clock and tick
    sprintf(gtrline(sc_dim[1]-1),
        "%lc",clkdr()

    );tick(gtevcnt());

    // run event loop
    keyrd();

// ---   *   ---   *   ---
// cleanup

  } while(PANIC_TIMER--);

  dpycl();
  return;

};

// ---   *   ---   *   ---

