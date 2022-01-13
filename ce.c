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

  #include <inttypes.h>

  #include <fcntl.h>
  #include <termios.h>
  #include <unistd.h>

  #include <locale.h>
  #include <time.h>

  #include <wchar.h>
  #include "chartab.h"

  #include <sys/ioctl.h>

// ---   *   ---   *   ---
// constants
  #define KBD_SZ 0x08
  #define CEB_SZ 0x400

// ---   *   ---   *   ---
// global state

  typedef struct {
    struct termios restore;
    struct winsize wsz;

    char buff[CEB_SZ];
    size_t buff_i;

    struct {
      int x;
      int y;

    } cursor;

    struct {
      uint64_t l;
      uint64_t r;

    } kbd;

  } STRUCT_CE;static STRUCT_CE CE={0};

// ---   *   ---   *   ---
// fwd decls
  void iclose(void);

// ---   *   ---   *   ---
// buffer utils

// manual cat
void badd(char* src) {
  strncpy(
    CE.buff+CE.buff_i,
    src,

    CEB_SZ-CE.buff_i

  );CE.buff_i+=strlen(src);
  CE.buff_i&=CEB_SZ-1;

// buffer wipe
};void bcl(void) {memset(CE.buff,0,CEB_SZ);};

// ---   *   ---   *   ---
// term utils

// open stdin raw
int iopen(void) {

  if(!isatty(STDIN_FILENO)) {
    printf("STDIN is not a tty\n");
    return 1;

  };atexit(iclose);

  // put tty in raw mode
  struct termios term={0};
  tcgetattr(STDIN_FILENO,&CE.restore);

  term.c_cc[VTIME]=2;
  term.c_cc[VMIN]=0;

  term.c_cflag|=(CS8);
  term.c_oflag&=~(OPOST);
  term.c_iflag&=~(BRKINT|INPCK|ISTRIP|IXON|ICRNL);
  term.c_lflag&=~(ICANON|ECHO|IEXTEN|ISIG);
  tcsetattr(STDIN_FILENO,TCSAFLUSH,&term);

  // get screen size
  ioctl(STDOUT_FILENO,TIOCGWINSZ,&CE.wsz);

  // clear screen and reposition
  badd("\e[?25l\e[2J\e[H");
  CE.cursor.x=0;CE.cursor.y=0;

  return 0;

// ^the undo for it
};void iclose(void) {
  tcsetattr(STDIN_FILENO,TCSAFLUSH,&CE.restore);
  write(STDOUT_FILENO,"\e[2J\e[H",7);

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
// keyhandler

void kev(void) {
  for(int x=0;x<8;x++) {

    int b=x*2;
    int y=(CE.kbd.l&(0b11<<b)) >> b;

    int held=(y&0b10)!=0;int tap=y&0b01;

    held=0b10<<b;
    tap=0b01<<b;
    int active=held|tap;

    CE.kbd.l&=~active;
    CE.kbd.l|=(y)*held;

    break;

  };
};

#include "keymap.h"

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

// ---   *   ---   *   ---

  // looparino
  );int x=1600;do {

    // refresh and wipe buffer
    if(CE.buff_i) {
      write(
        STDOUT_FILENO,
        CE.buff,
        CE.buff_i

      );bcl();badd("\e[?25l");
    };

// ---   *   ---   *   ---

    // print the clock and tick
    { char tmp[32];sprintf(tmp,
        "\e[%u;1H\e[2K%lc",

        CE.wsz.ws_row,
        clck.v[clck.vix]

      );badd(tmp);tick(&clck);
    };

// ---   *   ---   *   ---

    // capture this frames input
    read(STDIN_FILENO,kbd,KBD_SZ);

    // exit or process input
    if(*kbd_ptr) { if(kbd[0]=='Q') {break;};

      // print the code for debug
      char tmp[64];sprintf(tmp,
        "\e[%u;1H%016"PRIX64"\e[K",
        CE.wsz.ws_row-1,
        *kbd_ptr

      );badd(tmp);

      keychk(*kbd_ptr);*kbd_ptr^=*kbd_ptr;

    };kev();

// ---   *   ---   *   ---

    // move cursor to pos and unhide
    { char tmp[64];sprintf(tmp,
        "\e[%u;%uH\e[?25h",
        CE.cursor.y+1,
        CE.cursor.x+1

      );badd(tmp);
    };

  } while(x--);
  return;

};

// ---   *   ---   *   ---
