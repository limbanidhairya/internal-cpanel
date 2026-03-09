/*
 * libcpanel_hook.c - Static Bypass (v11.1)
 *
 * Modified to compile without -ldl due to WSL linker constraints.
 * Uses direct interception without resolving original symbols where possible.
 */

#include <ifaddrs.h>
#include <net/if.h>
#include <netpacket/packet.h>
#include <stdio.h>
#include <string.h>


// Valid MAC context
unsigned char VALID_MAC[] = {0x00, 0x15, 0x5d, 0x01, 0xcd, 0x24};

// We intercept getifaddrs. Since we aren't using dlsym, we simply construct a
// fake interface list.
int getifaddrs(struct ifaddrs **ifap) {
  // For a minimal bypass, often just returning 0 and a null list
  // or a single hardcoded entry is enough to foil generic HW checks.
  // However, returning a single fake 'eth0' is safer.

  // Allocating dummy structure
  static struct ifaddrs fake_ifa;
  static struct sockaddr_ll fake_sll;

  memset(&fake_ifa, 0, sizeof(struct ifaddrs));
  memset(&fake_sll, 0, sizeof(struct sockaddr_ll));

  fake_ifa.ifa_name = "eth0";
  fake_ifa.ifa_addr = (struct sockaddr *)&fake_sll;
  fake_ifa.ifa_next = NULL;

  fake_sll.sll_family = AF_PACKET;
  fake_sll.sll_halen = 6;
  memcpy(fake_sll.sll_addr, VALID_MAC, 6);

  *ifap = &fake_ifa;

  return 0; // Success
}

// Minimal stub for testing if this compiles
static void __attribute__((constructor)) init() {
  // Dummy init
}
