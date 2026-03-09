#!/usr/bin/env python3

import sys
import os

def patch_file(filepath):
    print(f"Processing {filepath}...")
    if not os.path.exists(filepath):
        print(f"File {filepath} not found.")
        return

    with open(filepath, 'rb') as f:
        data = f.read()

    patches = [
        (b"is_licensed", b"zt_licensed"),
        (b"Cpanel::License", b"Cpanel::Xicense")
    ]

    modified = False
    for original, replacement in patches:
        count = data.count(original)
        if count > 0:
            print(f"Found {count} occurrences of {original}")
            data = data.replace(original, replacement)
            modified = True
        else:
            print(f"No occurrences of {original} found.")

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
