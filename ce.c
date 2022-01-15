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

  #include <dirent.h>
  #include <limits.h>
  #include <linux/kd.h>
  #include <sys/ioctl.h>
  #include <sys/types.h>
  #include <sys/stat.h>

// ---   *   ---   *   ---
// just to make sure we don't
// exit without restoring term
  #include <signal.h>

void onsegv(int sig) {
  printf(
    "\n!!(0): "
    "I messed up the math somewhere\n");

  exit(1);

};

// ---   *   ---   *   ---
// constants
  #define KBD_SZ 0x08
  #define CEB_SZ 0x1000

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

    int kbd[128];

    struct {
      char lines[64][128];

    } render;

    int mode;

  } STRUCT_CE;static STRUCT_CE CE={0};

// ---   *   ---   *   ---

  enum CE_MODES {
    CE_MTEXT,
    CE_MKEYS

  };

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
};void bcl(void) {
  memset(CE.buff,0,CEB_SZ);
  CE.buff_i^=CE.buff_i;

};

// ---   *   ---   *   ---

// draw the buffer
void brend(void) {

  // wipe screen, reposition
  char m[128];

  // dump lines on draw buffer
  for(int y=0;y<CE.wsz.ws_row;y++) {

    if(!CE.render.lines[y]) {continue;}

    sprintf(m,
      "\e[%u;1H%s",

      y+1,CE.render.lines[y]

    );badd(m);
    memset(CE.render.lines[y],0,128);

  };

// ---   *   ---   *   ---

  // move cursor to pos and unhide
  sprintf(m,
    "\e[%u;%uH\e[?25h",
    CE.cursor.y+1,
    CE.cursor.x+1

  );badd(m);

  write(
    STDOUT_FILENO,
    CE.buff,
    CE.buff_i

  );bcl();badd("\e[?25l");
};

// ---   *   ---   *   ---
// term utils

// open stdin raw
int iopen(void) {

  if(!isatty(STDIN_FILENO)) {
    printf("STDIN is not a tty\n");
    return 1;

  };

  // save original attrs
  struct termios term={0};
  tcgetattr(STDIN_FILENO,&CE.restore);

  // ensure unexpected segfaults
  // cant lock me in raw mode
  signal(SIGSEGV,onsegv);
  atexit(iclose);

  // put tty in raw mode
  term.c_cc[VTIME]=3;
  term.c_cc[VMIN]=0;

  term.c_cflag|=(CS8);
  term.c_oflag&=~(OPOST);
  term.c_iflag&=~(BRKINT|INPCK|ISTRIP|IXON|ICRNL);
  term.c_lflag&=~(ICANON|ECHO|IEXTEN|ISIG);
  tcsetattr(STDIN_FILENO,TCSAFLUSH,&term);

  // we dont want to read no ascii codes
  ioctl(STDIN_FILENO,KDSKBMODE,K_MEDIUMRAW);

  // get screen size
  ioctl(STDOUT_FILENO,TIOCGWINSZ,&CE.wsz);

  // clear screen and reposition
  badd("\e[2J\e[H\e[?25l");
  CE.cursor.x=0;CE.cursor.y=0;

  return 0;

// ^the undo for it
};void iclose(void) {
  ioctl(STDIN_FILENO,KDSKBMODE,K_XLATE);
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
// keyhandling

// generated imports
  #include "keymap.h"
  #include "chartab.h"

// [manually written code goes here]

// ---   *   ---   *   ---

void main(int argc,char** argv) {

  do {
    if(!strcmp(*argv,"-k")) {
      CE.mode=CE_MKEYS;

    };argv++;argc--;

  } while(argc);

  // open stdin for non-blocking io
  // also ensure we can use lycon chars
  iopen();setlocale(LC_ALL,"");

// ---   *   ---   *   ---

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
  );int PANIC_TIMER=1600;do {

    // render last frame
    brend();

    // update the draw clock and tick
    sprintf(CE.render.lines[CE.wsz.ws_row-1],
        "%lc",clck.v[clck.vix]

    );tick(&clck);

// ---   *   ---   *   ---

    // capture this frames input
    read(STDIN_FILENO,kbd,KBD_SZ);

    // exit or process input
    if(*kbd_ptr) { if(*kbd_ptr==0x91) {break;};

      char key_id=(*kbd_ptr)&0x7F;

      key_id*=
        key_id<( sizeof(KEY_NAMES)/sizeof(char*) );

      char key_rel=*kbd_ptr==key_id+0x80;

      // print the code for debug
      sprintf(CE.render.lines[CE.wsz.ws_row-1]+2,
        " | %016"PRIX64" | %s %d\e[K",*kbd_ptr,
        KEY_NAMES[key_id], key_rel

      );keyset(key_id,key_rel);
      *kbd_ptr^=*kbd_ptr;

    };keychk();

// ---   *   ---   *   ---

  } while(PANIC_TIMER--);
  return;

};

// ---   *   ---   *   ---

