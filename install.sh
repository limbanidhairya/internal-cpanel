#!/bin/bash

# --- Internal cPanel Build Installer (Patch-Based) ---
# Purpose: Clean system, install cPanel binaries, and apply bypass hot-patches.

echo "[*] Initializing Internal cPanel Build Setup..."

# 1. System Preparation
# Ensure DNS is working (Add Google DNS as primary)
echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf
# Attempt to prevent overwrite
chattr +i /etc/resolv.conf 2>/dev/null

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
else
    echo "[!] Unsupported OS distribution."
    exit 1
fi

echo "[*] Detected $ID. Updating package list..."
# Handle apt locks
if [ "$OS_ID" == "ubuntu" ] || [ "$OS_ID" == "debian" ]; then
    echo "[*] Waiting for other package managers to finish..."
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
        sleep 5
    done
fi

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
if ! curl -o latest -L https://secured.cpanel.net/latest; then
    echo "[X] Error: Could not download cPanel installer. DNS or Network issue."
    # Temporary fallback: try to resolve via IP if possible or exit
    exit 1
fi

if [ ! -s "latest" ]; then
    echo "[X] Error: Downloaded installer is empty."
    exit 1
fi

echo "[!] Initiating cPanel installation process (Background)..."
chmod +x latest
sh latest --force > /var/log/cpanel_install_main.log 2>&1 &
INSTALL_PID=$!
echo "[*] cPanel installation started (PID: $INSTALL_PID). Logging to /var/log/cpanel_install_main.log"

# 4. Wait & Hot-Patch Logic
# We need to wait for cPanel to create the directory structure before applying patches.
echo "[*] Monitoring installation progress for patch window..."
MAX_RETRIES=20
COUNT=0
while [ ! -d "/usr/local/cpanel/Cpanel" ]; do
    echo "[.] Waiting for /usr/local/cpanel/Cpanel to be created... ($COUNT/$MAX_RETRIES)"
    sleep 30
    COUNT=$((COUNT+1))
    if [ $COUNT -ge $MAX_RETRIES ]; then
        echo "[X] Timeout: /usr/local/cpanel/Cpanel never appeared. cPanel install likely failed."
        echo "[*] Check /var/log/cpanel_install_main.log for details."
        exit 1
    fi
done

echo "[*] Applying bypass hot-patches from $INSTALL_DIR/patches..."

# Perl Module Overwrites (Ensure case-sensitive matching)
cp -f "$INSTALL_DIR/patches/License.pm" "/usr/local/cpanel/Cpanel/License.pm" || echo "[!] License.pm failed"
cp -f "$INSTALL_DIR/patches/Whostmgr_Plugin.pm" "/usr/local/cpanel/Cpanel/Template/Plugin/Whostmgr.pm" || echo "[!] Whostmgr_Plugin.pm failed"
cp -f "$INSTALL_DIR/patches/Whostmgr_API_Cpanel.pm" "/usr/local/cpanel/Whostmgr/API/1/Cpanel.pm" || echo "[!] Whostmgr_API_Cpanel.pm failed"
cp -f "$INSTALL_DIR/patches/Whostmgr/Setup/Completed.pm" "/usr/local/cpanel/Whostmgr/Setup/Completed.pm" || echo "[!] Completed.pm failed"
cp -f "$INSTALL_DIR/patches/Whostmgr/Setup/EULA.pm" "/usr/local/cpanel/Whostmgr/Setup/EULA.pm" || echo "[!] EULA.pm failed"
cp -f "$INSTALL_DIR/patches/Cpanel/Config/Sources.pm" "/usr/local/cpanel/Cpanel/Config/Sources.pm" || echo "[!] Sources.pm failed"
cp -f "$INSTALL_DIR/patches/Cpanel/Config/CpConfGuard.pm" "/usr/local/cpanel/Cpanel/Config/CpConfGuard.pm" || echo "[!] CpConfGuard.pm failed"

# Template Redirection Fixes
cp -f "$INSTALL_DIR/patches/base/unprotected/lisc/licenseerror_whm.tmpl" "/usr/local/cpanel/base/unprotected/lisc/licenseerror_whm.tmpl" || echo "[!] licenseerror_whm.tmpl failed"

# Fix case-sensitive path for Whostmgr templates
mkdir -p /usr/local/cpanel/whostmgr/docroot/templates/gsw/initial_setup
cp -f "$INSTALL_DIR/patches/Whostmgr/docroot/templates/gsw/initial_setup/license_purchase_intro.tmpl" "/usr/local/cpanel/whostmgr/docroot/templates/gsw/initial_setup/license_purchase_intro.tmpl" || echo "[!] license_purchase_intro.tmpl failed"

# 5. Post-Patch Configuration
echo "[*] Creating required state files..."
touch /etc/.whostmgrsetup
echo "setup=1" >> /var/cpanel/cpanel.config
# Redirect verification domains as per HANDOFF.md
# (Assuming Sources.pm handles this via logic, but we can also use /etc/hosts if needed)

echo "[*] Internal Build patches applied. Restarting services..."
/usr/local/cpanel/scripts/restartsrv_cpsrvd

# 6. Firewall Configuration
echo "[*] Configuring firewall for WHM/cPanel access..."
if command -v ufw >/dev/null 2>&1; then
    ufw allow 2087/tcp
    ufw allow 2086/tcp
    ufw allow 2083/tcp
    ufw allow 2082/tcp
    ufw reload
elif command -v iptables >/dev/null 2>&1; then
    iptables -I INPUT -p tcp --dport 2087 -j ACCEPT
    iptables -I INPUT -p tcp --dport 2086 -j ACCEPT
    iptables -I INPUT -p tcp --dport 2083 -j ACCEPT
    iptables -I INPUT -p tcp --dport 2082 -j ACCEPT
fi

echo "[*] Setup complete. Access WHM on https://103.233.65.233:2087"
echo "Note: If the dashboard still prompts for setup, the installer may have overwritten the patches. Run $INSTALL_DIR/install.sh again."
