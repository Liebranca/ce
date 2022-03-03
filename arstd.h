#ifndef __ARSTD_H__
#define __ARSTD_H__

#ifdef ___cplusplus
extern "C" {
#endif

// ---   *   ---   *   ---

// frees and nulls a ptr
void sfree(void** ptr);

// ---   *   ---   *   ---

#define PASS_ARGV(x) sizeof(x)/sizeof(x[0]),x

// fork, call process and capture output
char* ex(int argc,char** argv);

// basic chvt wrapper
void swtty(int dir,char* ctty);

// tty size in chars
void ttysz(int* dst);

// find X win id associated with (p)pid
int findwin(void);

// ---   *   ---   *   ---

#ifdef ___cplusplus
}
#endif

#endif // __ARSTD_H__
