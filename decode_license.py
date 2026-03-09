#!/usr/bin/env python3
import base64
import os
import re

input_file = "/usr/local/cpanel/cpanel.lisc"
output_file = "/mnt/c/Users/Dhairya Limbani/OneDrive/Documents/dcpanel/decoded_license.txt"

print(f"Decoding binary content from {input_file} (Binary Mode)...")

if not os.path.exists(input_file):
    print(f"Error: {input_file} not found.")
    exit(1)

try:
    with open(input_file, 'rb') as f:
        raw_bytes = f.read()
    
    # Extract only valid B64 characters from binary file
    b64_pattern = rb'[A-Za-z0-9+/=]+'
    potential_b64 = b"".join(re.findall(b64_pattern, raw_bytes))
    
    try:
        decoded_bytes = base64.b64decode(potential_b64)
        print("B64 Decoded Successfully.")
    except Exception as b64e:
        print(f"B64 Decode Failed: {b64e}. Trying direct string extraction.")
        decoded_bytes = raw_bytes

    # Extract readable strings (4+ printable chars)
    readable_strings = re.findall(rb'[ -~]{4,}', decoded_bytes)
    
    print("\n--- Extracted License Metadata ---")
    with open(output_file, 'w') as f:
        f.write("--- cPanel Decoded License Info ---\n")
        f.write(f"Source: {input_file}\n\n")
        f.write("Extracted Strings:\n")
        for s in readable_strings:
            text = s.decode('ascii', errors='ignore')
            if len(text) > 10: # Only show significant strings in console
                print(f"  {text}")
            f.write(f"{text}\n")
    
    print(f"\nSuccess: Decoded strings saved to {output_file}")

except Exception as e:
    # Final fallback: just extract strings from raw file
    print(f"Advanced Extraction failed: {e}. Falling back to basic string dump.")
    os.system(f"strings {input_file} > '{output_file}'")
    print(f"Success: Strings dumped to {output_file}")
