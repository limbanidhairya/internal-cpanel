#!/usr/bin/env python3

import sys
import os

def patch_file(filepath):
    print(f"Aggressive processing {filepath}...")
    if not os.path.exists(filepath):
        return

    with open(filepath, 'rb') as f:
        data = f.read()

    patches = [
        (b"report_license_error", b"zt_port_lic_error"),
        (b"check_and_fix_license", b"zt_ck_fix_license"),
        (b"valid_license", b"zt_lic_valid"),
        (b"Cpanel::License::Verify", b"Cpanel::Xicense::Verif"),
        (b"is_DNSONLY", b"is_WICENSED"),
        (b"is_dnsonly", b"is_wicensed")
    ]

    modified = False
    for original, replacement in patches:
        count = data.count(original)
        if count > 0:
            print(f"Found {count} occurrences of {original}")
            data = data.replace(original, replacement)
            modified = True

    if modified:
        with open(filepath, 'wb') as f:
            f.write(data)
        print(f"Successfully patched {filepath}")
    else:
        print(f"No patches were applied to {filepath}")

if __name__ == "__main__":
    binaries = [
        "/usr/local/cpanel/whostmgr/bin/whostmgr10",
        "/usr/local/cpanel/cpsrvd"
    ]
    for b in binaries:
        patch_file(b)
