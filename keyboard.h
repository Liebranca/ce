#ifndef __KEYBOARD_H__
#define __KEYBOARD_H__

#ifdef __cplusplus
extern "C" {
#endif

// ---   *   ---   *   ---
// types

#ifndef NIHIL_FUNC
#define NIHIL_FUNC
typedef void(*nihil)(void);
#endif

// ---   *   ---   *   ---
// for testing only
# include "keymap.h"

// ---   *   ---   *   ---
// methods

// start the input handler
int keynt(int fd);

// clear out state for a key
void keycl(char key);

// set key callback
void keycall(char key,int mode,nihil func);

// get tap/hel/rel state
char keytap(char key);
char keyhel(char key);
char keyrel(char key);

// postpone repeat delay
void keycool(void);

// dummy, exposed for convenience
void keyskip(void);

// capture input
void keyrd(void);

// save input char
void keyibs(char key);

// get events left in queue
int gtevcnt(void);

// ---   *   ---   *   ---

#ifdef __cplusplus
};
#endif

#endif // __KEYBOARD_H__
