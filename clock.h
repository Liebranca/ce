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
void clkmk(
  uint64_t flen,
  const wchar_t* v,
  uint32_t vsz

);

// run the clock for this frame
void tick(size_t busy,char* linger);

// get draw-clock char
wchar_t clkdr(void);

// ---   *   ---   *   ---

#ifdef __cplusplus
};
#endif

#endif // __CLOCK_H__
