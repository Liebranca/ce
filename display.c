// ---   *   ---   *   ---
// DPY
// Handles what you see
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
  #include <locale.h>

// ---   *   ---   *   ---
// constants
  #define RBUFF_SZ 0x1000

  #define RLINE_SZY 0x40
  #define RLINE_SZX 0x80

// ---   *   ---   *   ---
// global state

typedef struct DPY {

  // screen cursor
  union {
    struct {
      int x;
      int y;

    };int f[2];
  } cursor;

  // screen size
  union {
    struct {
      int x;
      int y;

    };int f[2];
  } wsz;

  // user-end canvas
  char rlines[RLINE_SZY][RLINE_SZX];

  // raw drawing buffer
  char rbuff[RBUFF_SZ];
  size_t rbuff_i;

  int fd;

};

// ---   *   ---   *   ---
// getters

char** gtrline(DPY* dpy,size_t idex) {
  return dpy->rlines[idex&(RLINE_SZY-1)];

};

int* gtcursor(DPY* dpy) {return dpy->cursor.f;};
int* gtwsz(DPY* dpy) {return dpy->wsz.f;};

// ---   *   ---   *   ---
// buffer utils

// manual cat
void badd(DPY* dpy,char* src) {
  strncpy(
    dpy->rbuff+dpy->rbuff_i,
    src,

    RBUFF_SZ-dpy->rbuff_i

  );dpy->rbuff_i+=strlen(src);
  dpy->rbuff_i&=RBUFF_SZ-1;

// buffer wipe
};void bcl(DPY* dpy) {
  memset(dpy->rbuff,0,RBUFF_SZ);
  dpy->rbuff_i^=dpy->rbuff_i;

};

// ---   *   ---   *   ---

// draw the buffer
void dpyrend(DPY* dpy) {

  // recycle mem
  char m[128];

  // dump lines on draw buffer
  for(int y=0;y<dpy->wsz.y;y++) {

    if(!dpy->rlines[y]) {continue;}

    sprintf(m,
      "\e[%u;1H%s",

      y+1,dpy->rlines[y]

    );badd(dpy,m);
    memset(dpy->rlines[y],0,128);

  };

// ---   *   ---   *   ---

  // move cursor to pos and unhide
  sprintf(m,
    "\e[%u;%uH\e[?25h",
    dpy->cursor.y+1,
    dpy->cursor.x+1

  );badd(dpy,m);

  write(
    dpy->fd,
    dpy->rbuff,
    dpy->rbuff_i

  );bcl(dpy);badd(dpy,"\e[?25l");
};

// ---   *   ---   *   ---

// wsz=ptr to x,y screen size
// cursor=ptr to x,y coords
// lines=draw-to strarr

// nit the display
DPY* dpynt(int fd) {

  DPY* dpy=malloc(sizeof(DPY));
  memset(dpy,0,sizeof(DPY));

  dpy->fd=fd;

  // get window size
  struct winsize w;
  ioctl(dpy->fd,TIOCGWINSZ,&w);
  dpy->wsz.x=w.ws_col;dpy->wsz.y=w.ws_row;

  // clear screen and reposition
  badd(dpy,"\e[2J\e[H\e[?25l");
  dpy->cursor.x=0;dpy->cursor.y=0;

  // ensure we can use lycon chars
  setlocale(LC_ALL,"");

  return dpy;

};

// clear screen
void dpycl(DPY* dpy) {
  write(dpy->fd,"\e[2J\e[H",7);

};

// ---   *   ---   *   ---


