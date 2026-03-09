#!/usr/bin/env python3

import sys
import os

def revert_everything(filepath):
    print(f"Reverting {filepath} to original state...")
    if not os.path.exists(filepath):
        return

    with open(filepath, 'rb') as f:
        data = f.read()

    # Revert all our known string patches
    patches = [
        (b"zt_licensed", b"is_licensed"),
        (b"Cpanel::Xicense", b"Cpanel::License"),
        (b"zt_port_lic_error", b"report_license_error"),
        (b"zt_ck_fix_license", b"check_and_fix_license"),
        (b"zt_lic_valid", b"valid_license"),
        (b"Cpanel::Xicense::Verif", b"Cpanel::License::Verify"),
        (b"is_WICENSED", b"is_DNSONLY"),
        (b"is_wicensed", b"is_dnsonly")
    ]

    modified = False
    for replacement, original in patches:
        count = data.count(replacement)
        if count > 0:
            print(f"Found {count} occurrences of {replacement}, reverting to {original}")
            data = data.replace(replacement, original)
            modified = True

    if modified:
        with open(filepath, 'wb') as f:
            f.write(data)
        print(f"Successfully reverted strings in {filepath}")
    else:
        print(f"No patches found in {filepath}")

if __name__ == "__main__":
    binaries = [
        "/usr/local/cpanel/whostmgr/bin/whostmgr10",
        "/usr/local/cpanel/cpsrvd"
    ]
    for b in binaries:
        revert_everything(b)

    # Restore original templates
    print("Restoring templates...")
    os.system("cp /usr/local/cpanel/base/unprotected/lisc/licenseerror_whm.tmpl.bak /usr/local/cpanel/base/unprotected/lisc/licenseerror_whm.tmpl 2>/dev/null")
    os.system("rm /var/cpanel/cpsrvd/unavailable 2>/dev/null")
    print("Cleanup complete.")
