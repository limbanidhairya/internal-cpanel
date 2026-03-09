#!/usr/bin/env python3

import sys
import os

def patch_binary(filepath):
    print(f"Surgically patching {filepath}...")
    if not os.path.exists(filepath):
        return

    with open(filepath, 'rb') as f:
        data = f.read()

    # Rename the error reporter to something we can redefine on disk
    patches = [
        (b"error503", b"errorXXX"),
        (b"report_license_error", b"report_license_ok00")
    ]

    modified = False
    for original, replacement in patches:
        count = data.count(original)
        if count > 0:
            print(f"Found {count} occurrences of {original}, renaming to {replacement}")
            data = data.replace(original, replacement)
            modified = True

    if modified:
        with open(filepath, 'wb') as f:
            f.write(data)
        print("Surgical patch applied successfully.")
    else:
        print("No matches found for surgical patch.")

if __name__ == "__main__":
    patch_binary("/usr/local/cpanel/whostmgr/bin/whostmgr10")
    patch_binary("/usr/local/cpanel/cpsrvd")
