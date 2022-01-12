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
  #include <string.h>
  #include <stdio.h>

  #include <inttypes.h>

  #include <fcntl.h>
  #include <termios.h>
  #include <unistd.h>

  #include <locale.h>
  #include <time.h>

  #include <wchar.h>
  #include "chartab.h"

// ---   *   ---   *   ---
// constants
  static const int FNO_STDIN=0;
  static const int KBD_SZ=16;

// ---   *   ---   *   ---
// term utils

// open stdin for real-time user input
int iopen(void) {

  if(!isatty(FNO_STDIN)) {
    printf("STDIN is not a tty\n");
    return 1;

  };struct termios term;
  tcgetattr(FNO_STDIN,&term);

  term.c_lflag&=~(ICANON|ECHO);
  tcsetattr(FNO_STDIN,TCSANOW,&term);
  fcntl(FNO_STDIN,F_SETFL,O_NONBLOCK);

  return 0;

// ^the undo for it
};void iclose(void) {

  struct termios term;
  tcgetattr(FNO_STDIN,&term);

  term.c_lflag|=(ICANON|ECHO);
  tcsetattr(FNO_STDIN,TCSANOW,&term);
  fcntl(FNO_STDIN,F_SETFL,~O_NONBLOCK);

};

// ---   *   ---   *   ---
// framecap utils

typedef struct {

  // frame measuring
  uint64_t fbeg;
  uint64_t fend;
  uint64_t flen;
  uint64_t delta;

  // chars for drawing
  wchar_t* v;
  uint32_t vix;
  uint32_t vsz;

  // constructor
} CLCK;CLCK mkclck(
  uint64_t flen,
  wchar_t* v,
  uint32_t vsz

) {CLCK c={0,clock(),flen,0,v,0,vsz};return c;};

// ---   *   ---   *   ---

// args= ptr to clock instance
// accumulate deltas and sleep if need be
void tick(CLCK* c) {
  c->fbeg=(uint64_t) clock();
  c->delta=c->fbeg - c->fend;
  c->fend=c->fbeg;

  if(c->delta<c->flen) {
    usleep(c->flen - c->delta);
    c->delta=0;

  };c->vix++;c->vix&=(c->vsz-1);

};

// ---   *   ---   *   ---

void main(void) {

  // open stdin for non-blocking io
  // also ensure we can use lycon chars
  iopen();setlocale(LC_ALL,"");

  // set aside memory for keyboard input
  char kbd[KBD_SZ];

  // shorthands/convenience
  uint64_t* kbd_ptr=(uint64_t*) kbd;
  uint64_t btt=0x00;

  // init the program clock
  CLCK clck=mkclck(

    0x8000,

    L"\x01A9\x01AA\x01AB\x01AC"
    L"\x01AD\x01AE\x01AF\x01B0",

    8

  // looparino
  );int x=1600;do {

    fflush(stdout);

    // print the clock and tick
    printf("%lc\e[1D",clck.v[clck.vix]);

    tick(&clck);

    // capture this frames input
    fgets(kbd,KBD_SZ,stdin);

    // early exit
    if(*kbd_ptr) { if(kbd[0]=='Q') {break;};
      btt=*kbd_ptr;*(kbd_ptr)^=*(kbd_ptr);

    };

    // bruteforce unlocked arrow keys for testing

           if(btt==0x415B1B) { printf("\e[1A");}
      else if(btt==0x425B1B) { printf("\e[1B");}
      else if(btt==0x435B1B) { printf("\e[1C");}
      else if(btt==0x445B1B) { printf("\e[1D");};

      btt^=btt;

  } while(x--);

  // cleanup
  printf("\n\n");
  iclose();return;

};

// ---   *   ---   *   ---
