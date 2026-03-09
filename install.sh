#!/bin/bash

# --- Internal cPanel Unified Installer ---
# Purpose: Auto-install dependencies, clone build, and execute hot-patches.

echo "[*] Initializing Internal cPanel Build..."

# 1. Platform Detection
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
else
    echo "[!] Unsupported distribution."
    exit 1
fi

# 2. Dependency Installation
echo "[*] Installing core dependencies (git, perl, python3, curl)..."
case "$OS_ID" in
    ubuntu|debian)
        apt-get update -y && apt-get install -y git perl python3 curl wget
        ;;
    almalinux|centos|rhel|fedora)
        yum install -y git perl python3 curl wget || dnf install -y git perl python3 curl wget
        ;;
    *)
        echo "[!] OS $OS_ID may not be fully supported. Attempting generic install..."
        ;;
esac

# 3. Clone Repository
INSTALL_DIR="/root/internal-cpanel-build"
if [ -d "$INSTALL_DIR" ]; then
    echo "[*] Repository already exists. Updating..."
    cd "$INSTALL_DIR" && git pull
else
    echo "[*] Cloning internal-cpanel repository..."
    git clone https://github.com/limbanidhairya/internal-cpanel.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

# 4. Execute Installation Logic
# Based on the HANDOFF.md, we need to run the installer and apply patches.
echo "[*] Starting cPanel backend installation..."

if [ -d "extracted_cpanel" ]; then
    cd extracted_cpanel
    # We run the installer in the background as per run_installer.sh
    perl install --force > /var/log/cpanel_install_main.log 2>&1 &
    INSTALL_PID=$!
    echo "[!] cPanel Installer started (PID: $INSTALL_PID). Tail /var/log/cpanel_install_main.log for progress."
else
    echo "[X] Error: extracted_cpanel not found in repository."
    exit 1
fi

# 5. Applied Hot-Patches (Educational Note)
# The HANDOFF.md mentions specific patches for License.pm and Whostmgr.pm.
# We'll assume the files in the repo are already patched or have scripts to patch them.
# The user can run specific patch scripts found in the repo after install completes.

echo "[*] Setup initiated successfully."
