#!/usr/bin/env python3
import os
import subprocess

def run(cmd):
    try:
        print(f"Executing: {cmd}")
        subprocess.run(cmd, shell=True, check=True)
    except Exception as e:
        print(f"Error: {e}")

def purge():
    print("Stopping cPanel services...")
    run("systemctl stop cpanel")

    print("Removing project artifacts...")
    targets = [
        "/usr/local/cpanel/cpsanitycheck.so",
        "/usr/local/cpanel/cpsrvd.so",
        "/usr/local/cpanel/Cpanel/Xicense.pm",
        "/usr/local/cpanel/Cpanel/License/Xerify.pm",
        "/usr/local/cpanel/cpanel.lisc",
        "/var/run/cpanel_bypass.lock"
    ]
    for t in targets:
        if os.path.exists(t):
            os.remove(t)
            print(f"Removed {t}")

    print("Restoring original templates and modules...")
    restorations = [
        ("/usr/local/cpanel/base/unprotected/lisc/licenseerror_whm.tmpl.bak", "/usr/local/cpanel/base/unprotected/lisc/licenseerror_whm.tmpl"),
        ("/usr/local/cpanel/Cpanel/License.pm.bak", "/usr/local/cpanel/Cpanel/License.pm"),
        ("/usr/local/cpanel/Cpanel/License/Verify.pm.bak", "/usr/local/cpanel/Cpanel/License/Verify.pm"),
        ("/usr/local/cpanel/whostmgr/bin/whostmgr10.bak", "/usr/local/cpanel/whostmgr/bin/whostmgr10"),
        ("/usr/local/cpanel/cpsrvd.bak", "/usr/local/cpanel/cpsrvd")
    ]
    for src, dst in restorations:
        if os.path.exists(src):
            run(f"cp -f {src} {dst}")
            print(f"Restored {dst}")

    print("Clearing systemd overrides...")
    override_dirs = [
        "/etc/systemd/system/cpanel.service.d",
        "/etc/systemd/system/cpsrvd.service.d"
    ]
    for d in override_dirs:
        if os.path.exists(d):
            run(f"rm -rf {d}")
            print(f"Removed override directory {d}")
    
    run("systemctl daemon-reload")

    print("Removing environment variables in /etc/environment...")
    if os.path.exists("/etc/environment"):
        with open("/etc/environment", "r") as f:
            lines = f.readlines()
        with open("/etc/environment", "w") as f:
            for line in lines:
                if "LD_PRELOAD" not in line and "WHM_DEVELOPMENT_MODE" not in line:
                    f.write(line)

    print("System Cleaned.")

if __name__ == "__main__":
    purge()
