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

  #include "display.h"

  #include <stdlib.h>
  #include <string.h>
  #include <stdio.h>

  #include <unistd.h>
  #include <locale.h>

  #include <sys/ioctl.h>

// ---   *   ---   *   ---
// constants

  #define RBUFF_SZ 0x1000

  #define RLINE_SZY 0x40
  #define RLINE_SZX 0x80

// ---   *   ---   *   ---
// global state

typedef struct {

  // screen cursor
  union {
    struct {
      int x;
      int y;

    };

    int f[2];

  } cursor;

  // screen size
  union {
    struct {
      int x;
      int y;

    };

    int f[2];

  } wsz;

  // user-end canvas
  char rlines[RLINE_SZY][RLINE_SZX];

  // raw drawing buffer
  char rbuff[RBUFF_SZ];
  size_t rbuff_i;

  int fd;

} DPY;static DPY dpy={0};

// ---   *   ---   *   ---
// getters

char* gtrline(size_t idex) {
  return dpy.rlines[idex&(RLINE_SZY-1)];

};

int* gtcursor(void) {return dpy.cursor.f;};
int* gtwsz(void) {return dpy.wsz.f;};

// ---   *   ---   *   ---
// cursor movement

void stcursor(int x,int y) {
  dpy.cursor.x=x;dpy.cursor.y=y;
  cursormv(0,0);

};

// ---   *   ---   *   ---

void cursormv(int x,int y) {

  // unconditionally add
  dpy.cursor.x+=x;dpy.cursor.y+=y;

  // cap x
  if(dpy.cursor.x>(dpy.wsz.x-1)) {
    dpy.cursor.x=0;dpy.cursor.y++;

  } else if(dpy.cursor.x<0) {
    dpy.cursor.x=(dpy.wsz.x-1);
    dpy.cursor.y--;

  };

  // cap y
  if(dpy.cursor.y>=(dpy.wsz.y-1)) {
    dpy.cursor.y=(dpy.wsz.y-1);

  } else if(dpy.cursor.y<0) {
    dpy.cursor.y=0;

  };

};

// ---   *   ---   *   ---
// buffer utils

// manual cat
void badd(char* src) {

  strncpy(
    dpy.rbuff+dpy.rbuff_i,
    src,

    RBUFF_SZ-dpy.rbuff_i

  );

  dpy.rbuff_i+=strlen(src);
  dpy.rbuff_i&=RBUFF_SZ-1;

};

// ---   *   ---   *   ---
// buffer wipe

void bcl(void) {
  memset(dpy.rbuff,0,RBUFF_SZ);
  dpy.rbuff_i^=dpy.rbuff_i;

};

// ---   *   ---   *   ---
// draw the buffer

void dpyrend(void) {

  // recycle mem
  char m[128];

  // dump lines on draw buffer
  for(int y=0;y<dpy.wsz.y;y++) {

    if(!dpy.rlines[y]) {continue;}

    sprintf(m,
      "\e[%u;1H%s",

      y+1,dpy.rlines[y]

    );

    badd(m);
    memset(dpy.rlines[y],0,128);

  };

// ---   *   ---   *   ---
// move cursor to pos and unhide

  sprintf(m,
    "\e[%u;%uH\e[?25h",
    dpy.cursor.y+1,
    dpy.cursor.x+1

  );

  badd(m);

  write(
    dpy.fd,
    dpy.rbuff,
    dpy.rbuff_i

  );

  bcl();
  badd("\e[?25l");

};

// ---   *   ---   *   ---
// nit the display

void dpynt(int fd) {

  memset(&dpy,0,sizeof(DPY));

  dpy.fd=fd;

  // get window size
  struct winsize w;
  ioctl(dpy.fd,TIOCGWINSZ,&w);
  dpy.wsz.x=w.ws_col;dpy.wsz.y=w.ws_row;

  // clear screen and reposition
  badd("\e[2J\e[H\e[?25l");
  dpy.cursor.x=0;dpy.cursor.y=0;

  // ensure we can use lycon chars
  setlocale(LC_ALL,"");

};

// clear screen
void dpycl(void) {
  write(dpy.fd,"\e[2J\e[H",7);

};

// ---   *   ---   *   ---


