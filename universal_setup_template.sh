#!/bin/bash

# --- PROFESSIONAL MULTI-DISTRO PROVISIONING TEMPLATE ---
# Educational guide for cross-distribution setup and networking.

# 1. Platform Detection
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$NAME
    OS_VERSION=$VERSION_ID
    OS_ID=$ID
else
    echo "Unsupported distribution."
    exit 1
fi

echo "Initializing setup for $OS_NAME $OS_VERSION ($OS_ID)..."

# 2. Package Manager Selection
case "$OS_ID" in
    ubuntu|debian)
        echo "Detected Debian/Ubuntu based system."
        PKG_MNGR="apt-get -y"
        PKG_UPDATE="$PKG_MNGR update"
        PKG_INSTALL="$PKG_MNGR install"
        ;;
    almalinux|centos|rhel|fedora)
        echo "Detected RHEL based system."
        PKG_MNGR="dnf -y"
        if ! command -v dnf &> /dev/null; then PKG_MNGR="yum -y"; fi
        PKG_UPDATE="$PKG_MNGR makecache"
        PKG_INSTALL="$PKG_MNGR install"
        ;;
    *)
        echo "OS ID $OS_ID is not explicitly supported by this template."
        exit 1
        ;;
esac

# 3. Base Dependencies
echo "Installing base utilities..."
$PKG_UPDATE
$PKG_INSTALL curl wget git perl python3

# 4. Networking: Static Internal IP Guidance
# Note: Netplan is standard on modern Ubuntu/Debian. 
# ifcfg/NetworkManager is standard on RHEL/CentOS.

configure_netplan() {
    echo "Configuring Netplan for Ubuntu/Debian..."
    cat <<EOF > /etc/netplan/99-static-internal.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth1: # Usually second interface for internal
      dhcp4: no
      addresses: [10.0.0.5/24]
EOF
    netplan apply
}

configure_nm() {
    echo "Configuring NetworkManager for RHEL/Alma..."
    # Educational example for nmcli
    # nmcli con mod eth1 ipv4.addresses 10.0.0.5/24 ipv4.method manual
    # nmcli con up eth1
}

# 5. Repository Preparation
echo "Setup complete. You can now manually clone your development repository"
echo "and apply your custom patches (State.pm, style_v2_optimized.css, etc.)"
echo "to this test environment."
