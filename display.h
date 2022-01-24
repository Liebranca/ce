#ifndef __DISPLAY_H__
#define __DISPLAY_H__

#ifdef __cplusplus
extern "C" {
#endif

// ---   *   ---   *   ---
// methods

// initialize display
void dpynt(int fd);

// clear the screen
void dpycl(void);

// write render buffer to out
void dpyrend(void);

// get draw target
char* gtrline(size_t idex);

// get/set/move cursor
int* gtcursor(void);
void stcursor(int x,int y);
void cursormv(int x,int y);

// get window dimentions
int* gtwsz(void);

// ---   *   ---   *   ---

#ifdef __cplusplus
};
#endif

#endif // __DISPLAY_H__
