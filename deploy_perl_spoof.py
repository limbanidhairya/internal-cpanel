#!/usr/bin/env python3
import os
import subprocess
import re

source_file = "/mnt/c/Users/Dhairya Limbani/OneDrive/Documents/dcpanel/Hardware_Spoof.pm"
dest_dir = "/usr/local/cpanel/Cpanel/custom"
dest_file = os.path.join(dest_dir, "Hardware_Spoof.pm")
env_file = "/etc/sysconfig/cpsrvdenv"

print("Deploying Perl Hardware Spoof...")

try:
    os.makedirs(dest_dir, exist_ok=True)
    subprocess.run(["cp", source_file, dest_file], check=True)
    print(f"Copied module to {dest_file}")

    # Add environment variables
    with open(env_file, 'a+') as f:
        f.seek(0)
        content = f.read()
        if "Cpanel/custom" not in content:
            f.write("\nexport PERL5LIB=\"/usr/local/cpanel/Cpanel/custom:$PERL5LIB\"\n")
        if "Hardware_Spoof" not in content:
            f.write("export PERL5OPT=\"-MHardware_Spoof\"\n")
            
    print("Environment variables updated.")
    
    print("Restarting cPanel services...")
    subprocess.run(["systemctl", "restart", "cpanel"], check=True)
    print("Deployment Successful.")
except Exception as e:
    print(f"Error during deployment: {e}")
