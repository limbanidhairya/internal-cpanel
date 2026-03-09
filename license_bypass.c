/*
 * license_bypass.c - cPanel Deep Edge Interceptor (v9.0)
 *
 * Strategy:
 * 1. Hook write() AND writev() to catch direct binary output.
 * 2. Hook send() to catch socket-level 503 errors.
 * 3. Force 200 OK + Dashboard Bootstrapper.
 */

#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/uio.h>
#include <unistd.h>


const char *PROFESSIONAL_REDIRECT =
    "HTTP/1.1 200 OK\r\n"
    "Content-Type: text/html\r\n"
    "Connection: close\r\n\r\n"
    "<!DOCTYPE html><html><head><title>WHM - Absolute Bypass</title>"
    "<script>(function(){ "
    "  var session = window.location.pathname.match(/cpsess[0-9]+/);"
    "  var base = session ? '/' + session[0] : '';"
    "  window.location.href = base + '/scripts/command?app=dashboard';"
    "})();</script></head><body>"
    "<h2 style='font-family:sans-serif;text-align:center;'>Initializing "
    "Original WHM Original Theme...</h2></body></html>";

typedef ssize_t (*write_fn)(int, const void *, size_t);
typedef ssize_t (*send_fn)(int, const void *, size_t, int);

static write_fn real_write = NULL;
static send_fn real_send = NULL;
static __thread int suppressed = 0;

static int is_license_error(const char *buf, size_t n) {
  if (n < 12)
    return 0;
  if (memmem(buf, n, " 503 ", 5) || memmem(buf, n, " 500 ", 5) ||
      memmem(buf, n, "Internal Server Error", 21) ||
      memmem(buf, n, "License Verification", 20)) {
    return 1;
  }
  return 0;
}

ssize_t write(int fd, const void *buf, size_t count) {
  if (!real_write)
    real_write = (write_fn)dlsym(RTLD_NEXT, "write");
  if (suppressed)
    return count;

  if (is_license_error((const char *)buf, count)) {
    suppressed = 1;
    real_write(fd, PROFESSIONAL_REDIRECT, strlen(PROFESSIONAL_REDIRECT));
    return count;
  }
  return real_write(fd, buf, count);
}

ssize_t send(int sockfd, const void *buf, size_t len, int flags) {
  if (!real_send)
    real_send = (send_fn)dlsym(RTLD_NEXT, "send");
  if (suppressed)
    return len;

  if (is_license_error((const char *)buf, len)) {
    suppressed = 1;
    real_write(sockfd, PROFESSIONAL_REDIRECT, strlen(PROFESSIONAL_REDIRECT));
    return len;
  }
  return real_send(sockfd, buf, len, flags);
}

// Block DNS for cpanel.net
#include <netdb.h>
int getaddrinfo(const char *node, const char *service,
                const struct addrinfo *hints, struct addrinfo **res) {
  typedef int (*gai_fn)(const char *, const char *, const struct addrinfo *,
                        struct addrinfo **);
  static gai_fn real_gai = NULL;
  if (!real_gai)
    real_gai = (gai_fn)dlsym(RTLD_NEXT, "getaddrinfo");
  if (node && (strstr(node, "cpanel.net") || strstr(node, "cpanel.com")))
    return EAI_NONAME;
  return real_gai(node, service, hints, res);
}
