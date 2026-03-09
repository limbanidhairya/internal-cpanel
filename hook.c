#define _GNU_SOURCE
#include <dlfcn.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>


// Assuming unthreaded Perl for cPanel
void (*my_Perl_eval_pv)(const char *p, int croak_on_error) = NULL;

int newfstatat(int dirfd, const char *pathname, struct stat *statbuf,
               int flags) {
  static int (*real_newfstatat)(int, const char *, struct stat *, int) = NULL;
  if (!real_newfstatat)
    real_newfstatat = dlsym(RTLD_NEXT, "newfstatat");

  if (pathname && strstr(pathname, "cpanel.lisc")) {
    // Find Perl_eval_pv dynamically
    if (!my_Perl_eval_pv) {
      my_Perl_eval_pv = dlsym(RTLD_DEFAULT, "Perl_eval_pv");
    }

    if (my_Perl_eval_pv) {
      // Inject our Perl snippet to force license validation to true!
      // Cpanel::License::is_licensed and valid_license
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
      fprintf(stderr, "[LD_PRELOAD] Injected Perl bytecode patches "
                      "successfully via Perl_eval_pv!\n");
    } else {
      fprintf(stderr,
              "[LD_PRELOAD] ERROR: Could not find Perl_eval_pv in memory!\n");
    }
  }

  return real_newfstatat(dirfd, pathname, statbuf, flags);
}
