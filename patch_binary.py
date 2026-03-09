#!/usr/bin/env python3

import sys

def patch_binary(filepath):
    print(f"Patching {filepath}...")
    with open(filepath, 'rb') as f:
        data = f.read()

    original = b"Cpanel::License"
    replacement = b"Cpanel::Xicense"

    count = data.count(original)
    print(f"Found {count} occurrences of {original}")

    if count > 0:
        new_data = data.replace(original, replacement)
        with open(filepath, 'wb') as f:
            f.write(new_data)
        print("Patch applied successfully.")
    else:
        print("No patch needed or string not found.")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: patch.py <binary>")
        sys.exit(1)
    patch_binary(sys.argv[1])
