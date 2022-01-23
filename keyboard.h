#ifndef __KEYBOARD_H__
#define __KEYBOARD_H__

#ifdef __cplusplus
extern "C" {
#endif

// ---   *   ---   *   ---
// types
typedef struct KBD KBD;

// ---   *   ---   *   ---
// methods

// start the input handler
KBD* keynt(int fd);

// capture input
void keyrd(KBD* kbd);

// get events left in queue
int gtevcnt(KBD* kbd);

// ---   *   ---   *   ---

#ifdef __cplusplus
};
#endif

#endif // __KEYBOARD_H__
