#define _GNU_SOURCE
#include <dlfcn.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>


void (*my_Perl_eval_pv)(const char *p, int croak_on_error) = NULL;

static void trigger_injection(void) {
  static int injected = 0;
  if (!injected) {
    if (!my_Perl_eval_pv) {
      void *handle = dlopen("/usr/local/cpanel/3rdparty/perl/542/lib/"
                            "x86_64-linux/CORE/libperl.so",
                            RTLD_LAZY | RTLD_NOLOAD);
      if (handle)
        my_Perl_eval_pv = dlsym(handle, "Perl_eval_pv");
      if (!my_Perl_eval_pv)
        my_Perl_eval_pv = dlsym(RTLD_DEFAULT, "Perl_eval_pv");
    }

    if (my_Perl_eval_pv) {
      const char *perl_code = "package Cpanel::License;"
                              "no warnings 'redefine';"
                              "sub is_licensed { return 1; }"
                              "sub valid_license { return 1; }"
                              "sub check_local_cache { return 1; }"
                              "sub get_license_ip { return '135.181.78.227'; }"
                              "package Whostmgr::HTMLInterface;"
                              "no warnings 'redefine';"
                              "sub report_license_error { return 1; }";
      my_Perl_eval_pv(perl_code, 0);
      fprintf(stderr,
              "[LD_PRELOAD] INJECTED PERL_EVAL_PV ON CPANEL.LISC OPEN64!\n");
    }
    injected = 1;
  }
}

int open(const char *pathname, int flags, ...) {
  static int (*real_open)(const char *, int, ...) = NULL;
  if (!real_open)
    real_open = dlsym(RTLD_NEXT, "open");
  int mode = 0;
  if (flags & O_CREAT) {
    va_list arg;
    va_start(arg, flags);
    mode = va_arg(arg, int);
    va_end(arg);
  }
  if (pathname && strstr(pathname, "cpanel.lisc"))
    trigger_injection();
  return real_open(pathname, flags, mode);
}

int open64(const char *pathname, int flags, ...) {
  static int (*real_open)(const char *, int, ...) = NULL;
  if (!real_open)
    real_open = dlsym(RTLD_NEXT, "open64");
  int mode = 0;
  if (flags & O_CREAT) {
    va_list arg;
    va_start(arg, flags);
    mode = va_arg(arg, int);
    va_end(arg);
  }
  if (pathname && strstr(pathname, "cpanel.lisc"))
    trigger_injection();
  return real_open(pathname, flags, mode);
}

int openat(int dirfd, const char *pathname, int flags, ...) {
  static int (*real_openat)(int, const char *, int, ...) = NULL;
  if (!real_openat)
    real_openat = dlsym(RTLD_NEXT, "openat");
  int mode = 0;
  if (flags & O_CREAT) {
    va_list arg;
    va_start(arg, flags);
    mode = va_arg(arg, int);
    va_end(arg);
  }
  if (pathname && strstr(pathname, "cpanel.lisc"))
    trigger_injection();
  return real_openat(dirfd, pathname, flags, mode);
}

int openat64(int dirfd, const char *pathname, int flags, ...) {
  static int (*real_openat64)(int, const char *, int, ...) = NULL;
  if (!real_openat64)
    real_openat64 = dlsym(RTLD_NEXT, "openat64");
  int mode = 0;
  if (flags & O_CREAT) {
    va_list arg;
    va_start(arg, flags);
    mode = va_arg(arg, int);
    va_end(arg);
  }
  if (pathname && strstr(pathname, "cpanel.lisc"))
    trigger_injection();
  return real_openat64(dirfd, pathname, flags, mode);
}
