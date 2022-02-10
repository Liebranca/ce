#ifndef __ARDEF_H__
#define __ARDEF_H__

#ifdef __cplusplus
extern "C" {
#endif

// ---   *   ---   *   ---

#ifndef NIHIL_FUNC
#define NIHIL_FUNC
typedef void(*nihil)(void);

#endif

#ifndef NOPE_FUNC
#define NOPE_FUNC
static void nope(void) {;};
#endif

// ---   *   ---   *   ---

#ifdef __cplusplus
};
#endif

#endif // __ARDEF_H__
