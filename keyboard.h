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
// methods

// start the input handler
int keynt(int fd);

// set key callback
void keycall(char key,int mode,nihil func);

// capture input
void keyrd(void);

// get events left in queue
int gtevcnt(void);

// ---   *   ---   *   ---

#ifdef __cplusplus
};
#endif

#endif // __KEYBOARD_H__
