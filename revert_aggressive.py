#!/usr/bin/env python3

import sys
import os

def revert_file(filepath):
    print(f"Reverting {filepath}...")
    if not os.path.exists(filepath):
        return

    with open(filepath, 'rb') as f:
        data = f.read()

    # Revert in REVERSE order of patching
    reverts = [
        (b"is_wicensed", b"is_dnsonly"),
        (b"is_WICENSED", b"is_DNSONLY"),
        (b"Cpanel::Xicense::Verif", b"Cpanel::License::Verify"),
        (b"zt_lic_valid", b"valid_license"),
        (b"zt_ck_fix_license", b"check_and_fix_license"),
        (b"zt_port_lic_error", b"report_license_error")
    ]

    modified = False
    for replacement, original in reverts:
        count = data.count(replacement)
        if count > 0:
            print(f"Found {count} occurrences of {replacement}, reverting to {original}")
            data = data.replace(replacement, original)
            modified = True

    if modified:
        with open(filepath, 'wb') as f:
            f.write(data)
        print(f"Successfully reverted {filepath}")
    else:
        print(f"No reverts were applied to {filepath}")

if __name__ == "__main__":
    binaries = [
        "/usr/local/cpanel/whostmgr/bin/whostmgr10",
        "/usr/local/cpanel/cpsrvd"
    ]
    for b in binaries:
        revert_file(b)
