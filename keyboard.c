// ---   *   ---   *   ---
// KBD
// handles your keys

// LIBRE SOFTWARE
// Licensed under GNU GPL3
// be a bro and inherit

// CONTRIBUTORS
// lyeb,
// ---   *   ---   *   ---

// deps

  #include <stddef.h>
  #include <string.h>
  #include <stdlib.h>
  #include <stdio.h>

  #include <termios.h>

  #include <linux/kd.h>
  #include <sys/ioctl.h>
  #include <sys/types.h>

  #include <signal.h>

// ---   *   ---   *   ---
// constants
  #define IBF_SZ 8

// ---   *   ---   *   ---
// global state

typedef struct {

  // key states
  int keys[K_COUNT];

  // event tracking
  int evstack[IBF_SZ];
  int evstack_i;
  int evlinger;
  int evcnt;

  // textual input
  char ibuff;

  // used to restore tty
  struct termios retore;

  // redundancy
  int fd;

} KBD;static KBD* G_KBD=NULL;

// ---   *   ---   *   ---
// getters

int gtevcnt(KBD* kbd) {
  return (kbd->evcnt!=0) && (kbd->evlinger!=0);

};

// ---   *   ---   *   ---
// just to make sure we don't
// exit without restoring term

void onsegv(int sig) {
  printf(
    "\n!!(0): "
    "I messed up the math somewhere\n");

  exit(1);

};

// ---   *   ---   *   ---
// fwd decls
  void iclose(void);

// ---   *   ---   *   ---
// term utils

// open stdin raw
int iopen(KBD* kbd) {

  if(!isatty(kbd->fd)) {

    fprintf(
      stderr,

      "FD %i is not a tty\n",
      kbd->fd

    );return -1;

  };

  // save original attrs
  struct termios term={0};
  tcgetattr(kbd->fd,&(kbd->restore));

  // ensure unexpected segfaults
  // cant lock me in raw mode
  signal(SIGSEGV,onsegv);
  atexit(iclose);

  // put tty in raw mode
  term.c_cc[VTIME]=0;
  term.c_cc[VMIN]=0;

  term.c_cflag|=(CS8);
  term.c_oflag&=~(OPOST);
  term.c_iflag&=~(BRKINT|INPCK|ISTRIP|IXON|ICRNL);
  term.c_lflag&=~(ICANON|ECHO|IEXTEN|ISIG);
  tcsetattr(kbd->fd,TCSAFLUSH,&term);

  // we dont want to read no ascii codes
  ioctl(kbd->fd,KDSKBMODE,K_MEDIUMRAW);
  G_KBD=kbd;

  return 0;

// ^the undo for it
};void iclose(void) {
  ioctl(G_KBD->fd,KDSKBMODE,K_XLATE);
  tcsetattr(G_KBD->fd,TCSAFLUSH,&(G_KBD->restore));

};

// ---   *   ---   *   ---
// generated imports
  #include "keymap.h"
  #include "chartab.h"

// ---   *   ---   *   ---

// KBD constructor
KBD* keynt(int fd) {

  KBD* kbd=malloc(sizeof(KBD));
  memset(kbd,0,sizeof(KBD));

  kbd->fd=fd;

  char ibuff[IBF_SZ];

  // read in nit trash and discard it
  iopen();read(kbd->fd,ibuff,IBF_SZ);
  { int d=8;while(d--) {
      read(kbd->fd,ibuff,IBF_SZ);
      usleep(0x4000);

    };
  };

  return kbd;

};

// ---   *   ---   *   ---

// captures this frames input
void keyrd(KBD* kbd) {

  char ibuff[IBF_SZ];
  uint64_t* input=(uint64_t*) ibuff;

  kbd->evlinger-=kbd->evlinger>0;
  read(kbd->fd,ibuff,IBF_SZ);

  // process input
  while(*input) {

    char key_id=(*input)&0x7F;

    key_id*=
      key_id<(K_COUNT);

    char key_rel=((*input)&0xFF)==key_id+0x80;

    keyset(kbd,key_id,key_rel);
    *input=(*input)>>8;

  };keychk(kbd);
};

// ---   *   ---   *   ---
