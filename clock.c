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

  #include <stdlib.h>
  #include <stdio.h>

  #include <time.h>
  #include <unistd.h>

// ---   *   ---   *   ---

struct CLK {

  // frame measuring
  uint64_t fbeg;
  uint64_t fend;
  uint64_t flen;
  uint64_t delta;

  // chars for drawing
  const wchar_t* v;
  uint32_t vix;
  uint32_t vsz;

};static CLK c={0};

// ---   *   ---   *   ---

// constructor
void clknt(
  uint64_t flen,
  const wchar_t* v,
  uint32_t vsz

) {

  memset(&c,0,sizeof(CLK));
  c=(CLK) {0,clock(),flen,0,v,0,vsz};

  return c;

};

// ---   *   ---   *   ---
// busy=handles sleep for longer

// frame-time calculator
void tick(int busy) {
  c.fbeg=(uint64_t) clock();
  c.delta=c.fbeg-c.fend;
  c.fend=c.fbeg;

  uint64_t m_flen=c.flen<<((!busy)*2);

  if(c.delta<m_flen) {
    usleep(m_flen-c.delta);
    c.delta=0;

  };c.vix++;c.vix&=(c.vsz-1);

};

// ---   *   ---   *   ---

// return clock char at this frame
// useless but cute
wchar_t clkdr(void) {
  return c.v[c.vix];

};

// ---   *   ---   *   ---
