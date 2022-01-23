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

};

// ---   *   ---   *   ---

// constructor
CLK* clknt(
  uint64_t flen,
  const wchar_t* v,
  uint32_t vsz

) {

  CLK* c=malloc(sizeof(CLK));
  *c=(CLK) {0,clock(),flen,0,v,0,vsz};

  printf("%ls\n",c->v);

  return c;

};

// ---   *   ---   *   ---

// c=ptr to program clock
// busy=event count
// linger=back-to-sleep cooldown

// frame-time calculator
void tick(CLK* c,int busy) {
  c->fbeg=(uint64_t) clock();
  c->delta=c->fbeg-c->fend;
  c->fend=c->fbeg;

  uint64_t m_flen=c->flen<<((!busy)*2);

  if(c->delta<m_flen) {
    usleep(m_flen-c->delta);
    c->delta=0;

  };c->vix++;c->vix&=(c->vsz-1);

};

// ---   *   ---   *   ---

// c=ptr to program clock

// return clock char at this frame
// useless but cute
wchar_t clkdr(CLK* c) {
  return c->v[c->vix];

};

// ---   *   ---   *   ---
