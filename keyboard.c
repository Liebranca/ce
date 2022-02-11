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

  #include "keyboard.h"

  #include <stddef.h>
  #include <inttypes.h>
  #include <string.h>
  #include <stdlib.h>
  #include <stdio.h>
  #include <stdbool.h>

  #include <unistd.h>

  #include <termios.h>

  #include <fcntl.h>
  #include <linux/kd.h>
  #include <sys/ioctl.h>
  #include <sys/types.h>
  #include <sys/stat.h>

  #include <limits.h>
  #include <signal.h>

  #include <X11/Xlib.h>

  // no idea where this is declared
  bool XkbSetDetectableAutoRepeat(
    Display* display,
    bool detectable,
    bool* supported_rtrn

  );

  #include "arstd.h"

// ---   *   ---   *   ---
// constants
  #define IBF_SZ 0x08
  #define REPEAT_DELAY 4

// ---   *   ---   *   ---
// macros
  #define IS_TAP(x) \
    ((kbd.keys[(x)*((x)<K_COUNT)]&0b001)>>0)

  #define IS_HEL(x) \
    ((kbd.keys[(x)*((x)<K_COUNT)]&0b010)>>1)

  #define IS_REL(x) \
    ((kbd.keys[(x)*((x)<K_COUNT)]&0b100)>>2)

typedef void(*rd_func)(char* ibuff);

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
  char ibuff[IBF_SZ];
  char ibuff_i;

  // used to restore tty
  struct termios restore;

  // redundancy
  int fd;
  char* envdpy;

  // X stuff
  Display* xdpy;
  Window xwin;

  rd_func f_krd;

} KBD;static KBD kbd={0};

// ---   *   ---   *   ---
// getters

// get events left in stack or delay cooldown
int gtevcnt(void) {
  return (kbd.evcnt!=0) || (kbd.evlinger>0);

};

// get key states
char keytap(char key) {
  return IS_TAP(key);

};char keyhel(char key) {
  return IS_HEL(key);

};char keyrel(char key) {
  return IS_REL(key);

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
  void xkeydl(void);

// ---   *   ---   *   ---
// term utils

// open stdin raw
int iopen(void) {

  if(!isatty(kbd.fd)) {

    fprintf(
      stderr,

      "FD %i is not a tty\n",
      kbd.fd

    );return -1;

  };

  // save original attrs
  struct termios term={0};
  tcgetattr(kbd.fd,&(kbd.restore));

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
  tcsetattr(kbd.fd,TCSAFLUSH,&term);

  // we dont want to read no ascii codes
  ioctl(kbd.fd,KDSKBMODE,K_MEDIUMRAW);

  return 0;

// ^the undo for it
};void iclose(void) {

  if(*kbd.envdpy) {xkeydl();};

  ioctl(kbd.fd,KDSKBMODE,K_XLATE);
  tcsetattr(kbd.fd,TCSAFLUSH,&(kbd.restore));

};

// ---   *   ---   *   ---

// clear all states/timers/events
void kbdcl(void) {
  memset(kbd.keys,0,K_COUNT*sizeof(kbd.keys[0]));

};

// clear state for a single key
void keycl(char key) {
  kbd.keys[key*(key<K_COUNT)]^=kbd.keys[key];

};

// repeat delay cooldown
void keycool(void) {
  kbd.evlinger+=8;kbd.evlinger&=0xF;

};

// ---   *   ---   *   ---

// save input byte
void keyibs(char key) {
  kbd.ibuff[kbd.ibuff_i]=key;
  kbd.ibuff_i++;kbd.ibuff_i&=(IBF_SZ-1);

};

// get input bytes
char* keyibl(void) {

  static char ibuff[IBF_SZ+1];

  strncpy(ibuff,kbd.ibuff,kbd.ibuff_i);
  memset(kbd.ibuff,0,kbd.ibuff_i);

  kbd.ibuff_i=0;
  return ibuff;

};

// ---   *   ---   *   ---
// event stack

// removes event from stack
void evpop(char key) {

  // find key and blank it
  char idex=0;for(char x=0;x<kbd.evstack_i;x++) {
    if(key==kbd.evstack[x]) {idex=x;break;};

  };kbd.evstack[idex]=0x00;

  // shift
  while(idex<kbd.evstack_i) {
    kbd.evstack[idex]=kbd.evstack[idex+1];
    idex++;

  };kbd.evstack_i--;
};

// puts event in stack
void evpush(char key) {

  // try to find key
  char do_push=1;for(char x=0;x<kbd.evstack_i;x++) {
    if(key==kbd.evstack[x]) {do_push=0;break;};

  // push if not found
  };if(do_push) {
    kbd.evstack[kbd.evstack_i]=key;
    kbd.evstack_i++;

  };
};

// ---   *   ---   *   ---
// callback tables

  // dummy/nop
  void keyskip(void){;};

  // these are filled out by the client
  static nihil K_TAP_FUNCS[K_COUNT+1]={keyskip};
  static nihil K_HEL_FUNCS[K_COUNT+1]={keyskip};
  static nihil K_REL_FUNCS[K_COUNT+1]={keyskip};

  // just a convenience
  static nihil* K_FUNCS[3]={
    K_TAP_FUNCS+0,
    K_HEL_FUNCS+0,
    K_REL_FUNCS+0

  };

// ---   *   ---   *   ---
// ^this is how

void keycall(
  char key,
  int mode,

  nihil func

) {K_FUNCS[mode&3][key+1]=func;};

// ---   *   ---   *   ---
// on-press flipper

void keyset(char key,char rel) {

  // translate
  char x=KEYLAY[key];

  // 0 is unused key or keyboard error
  if(!x || x>K_COUNT) {return;};x--;

  // tap/hel
  if(!rel) {

    // determine IS_TAP
    kbd.keys[x]&=~1;
    kbd.keys[x]|=(1*(!IS_HEL(x))|(x>=NON_TI));

    // ^make corresponding call if so
    K_TAP_FUNCS[(x+1)*IS_TAP(x)]();

    // register event
    evpush(x);return;

  };

// ---   *   ---   *   ---

  // unset tap/hel bits, set rel
  kbd.keys[x]&=~(0xFF03);
  kbd.keys[x]|=4;

  // unconditionally make call
  K_REL_FUNCS[x+1]();

  // unregister event
  evpop(x);


};

// ---   *   ---   *   ---
// event loop

void keychk(void) {

  // ensure top is nil
  kbd.keys[kbd.evstack_i]=0x00;
  kbd.evcnt^=kbd.evcnt;

  int* ev=kbd.evstack+0;
  int repeat=0;

  // iter events
  while(*ev) {int x=*ev;

    // get held counter and tick
    int ind_repeat=(kbd.keys[x]&0xFF00)>>8;
    kbd.keys[x]+=(1*(ind_repeat<REPEAT_DELAY))<<8;

    // get repeat triggers this frame
    repeat=(repeat!=0)|(ind_repeat==REPEAT_DELAY);
    K_HEL_FUNCS[(x+1)*IS_HEL(x)*repeat]();

    // update event count, set bits
    kbd.evcnt+=(kbd.keys[x]&0b111)!=0;
    kbd.keys[x]|=2*IS_TAP(x);
    kbd.keys[x]&=~5;

    // go to next
    ev++;

  };
};

// ---   *   ---   *   ---

void xkrd(char* ibuff) {

  int i=0;while(XPending(kbd.xdpy) && i<IBF_SZ) {

    XEvent ev;XNextEvent(kbd.xdpy,&ev);

    int idex=ev.xkey.keycode;

    if(XPending(kbd.xdpy)) {
      XEvent nev;XPeekEvent(kbd.xdpy,&nev);

      if(

        idex==nev.xkey.keycode
        && nev.xkey.time==ev.xkey.time

      ) {continue;};

    };

    char key=idex-8;
    key|=0x80*(ev.type==KeyRelease);

    *ibuff=key;ibuff++;i++;

  };

};void krd(char* ibuff) {
  read(kbd.fd,ibuff,IBF_SZ);

};

// ---   *   ---   *   ---
// X nit/del

void xkeynt(void) {

  kbd.xdpy=XOpenDisplay(kbd.envdpy);
  kbd.xwin=(Window) findwin();

  // handle auto repeat
  { bool r;

    XSelectInput(
      kbd.xdpy,
      kbd.xwin,
      KeyPressMask|KeyReleaseMask

    );/*XkbSetDetectableAutoRepeat(kbd.xdpy,1,&r);*/

  };kbd.f_krd=xkrd;

};void xkeydl(void) {XCloseDisplay(kbd.xdpy);};

// ---   *   ---   *   ---

// KBD constructor
int keynt(int fd) {

  memset(&kbd,0,sizeof(KBD));kbd.fd=fd;

  char ibuff[IBF_SZ];

  // go into raw mode
  if(iopen()) {
    fprintf(
      stderr,
      "Input handler failed it's own nit\n"

    );return -1;

  };

  // handle X
  kbd.envdpy=getenv("DISPLAY");
  if(*kbd.envdpy) {
    xkeynt();

  } else {kbd.f_krd=krd;};

  // read in nit trash and discard it
  read(kbd.fd,ibuff,IBF_SZ);
  { int d=8;while(d--) {
      read(kbd.fd,ibuff,IBF_SZ);
      usleep(0x6000);

    };
  };
};

// ---   *   ---   *   ---

// captures this frames input
void keyrd(void) {

  char ibuff[IBF_SZ];
  uint64_t* input=(uint64_t*) (ibuff+0);

  *input^=*input;

  kbd.evlinger-=kbd.evlinger>0;
  kbd.f_krd(ibuff);

  // process input
  while(*input) {

    char key_id=(*input)&0x7F;

    char key_rel=((*input)&0xFF)==(key_id+0x80);
    keyset(key_id,key_rel);

    *input=(*input)>>8;

  };keychk();

};

// ---   *   ---   *   ---
