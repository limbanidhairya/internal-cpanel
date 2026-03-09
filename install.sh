#!/bin/bash

# --- Internal cPanel Build Installer (Patch-Based) ---
# Purpose: Clean system, install cPanel binaries, and apply bypass hot-patches.

echo "[*] Initializing Internal cPanel Build Setup..."

# 1. System Preparation
# Ensure DNS is working (Add Google DNS temporarily as backup)
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
else
    echo "[!] Unsupported OS distribution."
    exit 1
fi

echo "[*] Detected $ID. Updating package list..."
case "$OS_ID" in
    ubuntu|debian)
        apt-get update -y && apt-get install -y git perl python3 curl wget
        ;;
    almalinux|centos|rhel|fedora)
        yum makecache -y && yum install -y git perl python3 curl wget
        ;;
esac

# 2. Clone Build Logic
INSTALL_DIR="/root/internal-cpanel-build"
echo "[*] Cloning repository for patches and logic..."
if [ -d "$INSTALL_DIR" ]; then
    cd "$INSTALL_DIR" && git pull
else
    git clone https://github.com/limbanidhairya/internal-cpanel.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# 3. Handle Binary Setup
echo "[*] Downloading official cPanel installer..."
curl -o latest -L https://secured.cpanel.net/latest

echo "[!] Initiating cPanel installation process (Background)..."
# We run with --force as per project context
sh latest --force > /var/log/cpanel_install_main.log 2>&1 &
INSTALL_PID=$!
echo "[*] cPanel installation started (PID: $INSTALL_PID). Logging to /var/log/cpanel_install_main.log"

# 4. Wait & Hot-Patch Logic
# We need to wait for cPanel to create the directory structure before applying patches.
echo "[*] Monitoring installation progress for patch window..."
# In a real scenario, this loop would wait for the directory to appear.
while [ ! -d "/usr/local/cpanel/Cpanel" ]; do
    echo "[.] Waiting for /usr/local/cpanel/Cpanel to be created..."
    sleep 30
done

echo "[*] Applying bypass hot-patches from $INSTALL_DIR/patches..."

# Perl Module Overwrites
cp -f "$INSTALL_DIR/patches/License.pm" "/usr/local/cpanel/Cpanel/License.pm"
cp -f "$INSTALL_DIR/patches/Whostmgr_Plugin.pm" "/usr/local/cpanel/Cpanel/Template/Plugin/Whostmgr.pm"
cp -f "$INSTALL_DIR/patches/Whostmgr_API_Cpanel.pm" "/usr/local/cpanel/Whostmgr/API/1/Cpanel.pm"
cp -f "$INSTALL_DIR/patches/Whostmgr/Setup/Completed.pm" "/usr/local/cpanel/Whostmgr/Setup/Completed.pm"
cp -f "$INSTALL_DIR/patches/Whostmgr/Setup/EULA.pm" "/usr/local/cpanel/Whostmgr/Setup/EULA.pm"
cp -f "$INSTALL_DIR/patches/Cpanel/Config/Sources.pm" "/usr/local/cpanel/Cpanel/Config/Sources.pm"
cp -f "$INSTALL_DIR/patches/Cpanel/Config/CpConfGuard.pm" "/usr/local/cpanel/Cpanel/Config/CpConfGuard.pm"

# Template Redirection Fixes
cp -f "$INSTALL_DIR/patches/base/unprotected/lisc/licenseerror_whm.tmpl" "/usr/local/cpanel/base/unprotected/lisc/licenseerror_whm.tmpl"

# Fix case-sensitive path for Whostmgr templates
mkdir -p /usr/local/cpanel/whostmgr/docroot/templates/gsw/initial_setup
cp -f "$INSTALL_DIR/patches/Whostmgr/docroot/templates/gsw/initial_setup/license_purchase_intro.tmpl" "/usr/local/cpanel/whostmgr/docroot/templates/gsw/initial_setup/license_purchase_intro.tmpl"

# 5. Post-Patch Configuration
echo "[*] Creating required state files..."
touch /etc/.whostmgrsetup
echo "setup=1" >> /var/cpanel/cpanel.config
# Redirect verification domains as per HANDOFF.md
# (Assuming Sources.pm handles this via logic, but we can also use /etc/hosts if needed)

echo "[*] Internal Build patches applied. Restarting services..."
/usr/local/cpanel/scripts/restartsrv_cpsrvd

echo "[*] Setup complete. Access WHM on port 2087."
echo "Note: If the dashboard still prompts for setup, the installer may have overwritten the patches. Run $INSTALL_DIR/install.sh again."
