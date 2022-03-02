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
// methods

// nit a new program clock
void clknt(
  uint64_t flen,
  wchar_t* v,
  uint32_t vsz

);

// run the clock for this frame
void tick(int busy);

// get draw-clock char
wchar_t clkdr(void);

// ---   *   ---   *   ---

#ifdef __cplusplus
};
#endif

#endif // __CLOCK_H__
