#ifndef __DISPLAY_H__
#define __DISPLAY_H__

#ifdef __cplusplus
extern "C" {
#endif

// ---   *   ---   *   ---
// types
typedef struct DPY DPY;

// ---   *   ---   *   ---
// methods

// initialize display
DPY* dpynt(int fd);

// clear the screen
void dpycl(DPY* dpy);

// write render buffer to out
void dpyrend(DPY* dpy);

// get draw target
char* gtrline(DPY* dpy,size_t idex);

// get screen cursor
int* gtcursor(DPY* dpy);

// get window dimentions
int* gtwsz(DPY* dpy);

// ---   *   ---   *   ---

#ifdef __cplusplus
};
#endif

#endif // __DISPLAY_H__
