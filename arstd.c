// ---   *   ---   *   ---
// ARSTD
// common routines
//
// LIBRE SOFTWARE
// Licensed under GNU GPL3
// be a bro and inherit
//
// CONTRIBUTORS
// lyeb,
// ---   *   ---   *   ---

#include "arstd.h"

#include <string.h>
#include <stdlib.h>
#include <stddef.h>
#include <stdio.h>
#include <stdint.h>

#include <fcntl.h>
#include <limits.h>
#include <unistd.h>

#include <errno.h>

#include <sys/wait.h>
#include <sys/ioctl.h>

// ---   *   ---   *   ---
// mem stuff

void sfree(void** ptr) {

  if(*ptr!=NULL) {
    free(*ptr);*ptr=NULL;

  };
};

// ---   *   ---   *   ---
// path stuff

static char** PATH;
static const size_t PATH_SZ=16;

// build strarr from search path
void getpath(void) {

  PATH=malloc(PATH_SZ*sizeof(char*));
  memset(PATH,0,PATH_SZ*sizeof(char*));

  // get current directory
  { static char cd[PATH_MAX+1];
    getcwd(cd,PATH_MAX);

    // ensure last char is /
    int len=strlen(cd);
    cd[len]='/';cd[len+1]=0x00;

    PATH[0]=malloc((len+2)*sizeof(char));
    strcpy(PATH[0],cd);

  };

// ---   *   ---   *   ---

  // get $ARPATH
  { char* arpath=getenv("ARPATH");
    int len=strlen(arpath);

    // copy and cat /bin/
    PATH[1]=malloc((len+2)*sizeof(char));
    strcpy(PATH[1],arpath);
    strcpy(PATH[1]+len,"/bin/");

  };

// ---   *   ---   *   ---

  // get $PATH
  {

    char* envpath;

    // copy environment variable
    { char*  ref_envpath=getenv("PATH");
      size_t len=strlen(ref_envpath);

      envpath=malloc(sizeof(char)*len);
      memcpy(envpath,ref_envpath,len);

    };

    char* token=strtok(envpath,":");

    int x=2;

    // break up $PATH
    while(token && x<PATH_SZ) {
      int len=strlen(token);
      PATH[x]=malloc((len+2)*sizeof(char));

      // ensure last char is /
      strcpy(PATH[x],token);
      PATH[x][len]='/';PATH[x][len+1]=0x00;

      // go to next
      token=strtok(NULL,":");x++;

    };

    free(envpath);

  };

// ---   *   ---   *   ---

// ^free strarr
};void freepath(void) {
  for(int x=0;x<PATH_SZ;x++) {
    if(PATH[x]) {free(PATH[x]);};

  };free(PATH);

// ---   *   ---   *   ---

// search name in path
};char* exsearch(char* ex_name) {

  getpath();

  // reserve some mem
  static char ex_path[PATH_MAX+1];
  int ex_err=1;

  // look for ex_name
  { char** p=PATH+0;
    while(p) {

    // cat
    strcpy(ex_path,*p);
    strcpy(ex_path+strlen(ex_path),ex_name);

    // validate
    ex_err=access(ex_path,X_OK);
    if(!ex_err) {
      break;

    };p++;

    // not found?
    };if(ex_err) {return NULL;};

  // found
  };freepath();
  return ex_path;

};

// ---   *   ---   *   ---

char* ex(int argc,char** argv) {

  int fd[2];pipe(fd);
  pid_t pid=fork();

  // child
  if(!pid) {

    dup2(fd[1],STDOUT_FILENO);
    close(fd[0]);
    close(fd[1]);

    // find executable
    char* ex_name=argv[0];
    char* ex_path=exsearch(ex_name);
    if(!ex_path) {
      fprintf(stderr,"%s not found!\n",ex_name);
      exit(-1);
    };

    // make strarr for args
    char** ex_argv=malloc((1+argc)*sizeof(char*));
    ex_argv[0]=ex_path;

    // copy args
    for(int x=1;x<argc;x++) {
      ex_argv[x]=malloc(
        strlen(argv[x])*sizeof(char)

      );strcpy(ex_argv[x],argv[x]);
    };ex_argv[argc]=NULL;
    execv(ex_argv[0],ex_argv);

    // you should never see this
    perror("execv");
    exit(-1);

// ---   *   ---   *   ---

  // parent
  };close(fd[1]);

  static char buff[0x1000];

  int fc=fcntl(fd[0],F_GETFL,0);
  fcntl(fd[0],F_SETFL,~FNONBLOCK);
  ssize_t rb=read(fd[0],buff,sizeof(buff));

  fcntl(fd[0],F_SETFL,fc);

  close(fd[0]);wait(0);

  return buff;

};

// ---   *   ---   *   ---

void swtty(int dir,char* ctty) {

  { char* ex_argv[]={"tty"};
    strcpy(ctty,ex(PASS_ARGV(ex_argv))+8);
    ctty[0x0F]=0x00;

  };int ntty=ctty[0]-0x30;ntty+=dir;

       if(ntty>6) {ntty=1;}
  else if(ntty<1) {ntty=6;};ctty[0]=ntty+0x30;

  { char* ex_argv[]={"chvt",ctty};
    ex(PASS_ARGV(ex_argv));

  };

};

// ---   *   ---   *   ---

void ttysz(int* dst) {

  struct winsize w;
  ioctl(1,TIOCGWINSZ,&w);

  dst[0]=w.ws_col;
  dst[1]=w.ws_row;

};

// ---   *   ---   *   ---

int findwin(void) {

  char* eptr;
  return (int) strtoul(

    getenv("WINDOWID"),
    &eptr,10

  );

// NOTE: this is for PID->WID lookup
// ... we actually don't need it ;>

//  char wid[64];
//  int pid=getpid();
//
//  sprintf(wid,"%u",pid);
//  char* ex_argv[]={"wpid",wid+0};
//
//  strcpy(wid, ex(PASS_ARGV(ex_argv)) );
//
//  char* eptr;
//  return (int) strtoul(wid,&eptr,10);

};

// ---   *   ---   *   ---
