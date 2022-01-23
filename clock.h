#ifndef __CLOCK_H__
#define __CLOCK_H__

#ifdef __cplusplus
extern "C" {
#endif

// ---   *   ---   *   ---
// deps

  #include <inttypes.h>
  #include <wchar.h>


// ---   *   ---   *   ---
// types

typedef struct CLK CLK;

// ---   *   ---   *   ---
// methods

// nit a new program clock
CLK* clkmk(
  uint64_t flen,
  const wchar_t* v,
  uint32_t vsz

);

// run the clock for this frame
void tick(CLK* c,size_t busy,char* linger);

// get draw-clock char
wchar_t clkdr(CLK* c);

// ---   *   ---   *   ---

#ifdef __cplusplus
};
#endif

#endif // __CLOCK_H__
