#ifndef __ARSTD_H__
#define __ARSTD_H__

#ifdef ___cplusplus
extern "C" {
#endif

// ---   *   ---   *   ---

#define PASS_ARGV(x) sizeof(x)/sizeof(x[0]),x

// fork, call process and capture output
char* ex(int argc,char** argv);

// basic chvt wrapper
void swtty(int dir,char* ctty);

// ---   *   ---   *   ---

#ifdef ___cplusplus
}
#endif

#endif // __ARSTD_H__
