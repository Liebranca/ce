// ---   *   ---   *   ---
// CLCK
// Program clock
//
// LIBRE SOFTWARE
// Licensed under GNU GPL3
// be a bro and inherit
//
// CONTRIBUTORS
// lyeb,

// ---   *   ---   *   ---
// deps

  #include "clock.h"

  #include <string.h>
  #include <stdlib.h>
  #include <stdio.h>

  #include <time.h>
  #include <unistd.h>

// ---   *   ---   *   ---

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

} CLK;

// ---   *   ---   *   ---
// GBL

  static CLK c;

// ---   *   ---   *   ---
// constructor

void clknt(

  uint64_t flen,

  wchar_t* v,
  uint32_t vsz

) {

  static wchar_t s[0x80];
  for(int x=0;x<vsz;x++) {
    s[x]=*(v+x);

  };

  memset(&c,0,sizeof(CLK));
  c=(CLK) {0,clock(),flen,0,s,0,vsz};

};

// ---   *   ---   *   ---
// frame-time calculator

void tick(int busy) {

  // get frame delta
  c.fbeg  = (uint64_t) clock();
  c.delta = c.fbeg-c.fend;
  c.fend  = c.fbeg;


  // adjust frame length
  // to sleep less on busy signal
  uint64_t ad_flen = c.flen << (2 *! busy);

  // ^sleep if delta under
  // adjusted frame length
  if(c.delta < ad_flen) {
    usleep(ad_flen-c.delta);
    c.delta=0;

  };


  // adv anim
  c.vix++;
  c.vix&=(c.vsz-1);

};

// ---   *   ---   *   ---
// return clock char at this frame
// useless but cute

wchar_t clkdr(void) {
  return *(c.v+c.vix);

};

// ---   *   ---   *   ---
