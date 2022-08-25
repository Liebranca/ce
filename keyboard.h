#ifndef __KEYBOARD_H__
#define __KEYBOARD_H__

#ifdef __cplusplus
extern "C" {
#endif

// ---   *   ---   *   ---
// deps

  #include "ardef.h"

// ---   *   ---   *   ---
// methods

// start the input handler
int keynt(

  // input file
  int fd,

  // key table data
  char* keylay,
  int* keyflags,

  int k_count,
  int non_ti

);

// convenience macro
#define KEYNT(fd) keynt(          \
  fd,&(KEYLAY[0]),&(KEYVARS[0]),  \
  K_COUNT,NON_TI                  \
                                  \
)

// ---   *   ---   *   ---

// clear out state for a key
void keycl(char key);

// set key callback
void keycall(

  // key name & mode (0:tap,1:hel,2:rel)
  char key,
  int mode,

  // pointer to void func(void)
  nihil func

);

// ---   *   ---   *   ---

// set repeat delay
void stevdlay(int dlay);

// get tap/hel/rel state
char keytap(char key);
char keyhel(char key);
char keyrel(char key);

// ---   *   ---   *   ---

// postpone repeat delay
void keycool(void);

// capture input
void keyrd(void);

// process events
void keychk(void);

// save input char
void keyibs(char key);

// get input chars
char* keyibl(void);

// get events left in queue
int gtevcnt(void);

// ---   *   ---   *   ---

#ifdef __cplusplus
};
#endif

#endif // __KEYBOARD_H__
