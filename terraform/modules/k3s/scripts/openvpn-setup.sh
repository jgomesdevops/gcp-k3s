#!/bin/bash

# OpenVPN Server Setup Script
# This script installs and configures OpenVPN using the angristan/openvpn-install script

set -e

# Log function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Update system
log "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install required packages
log "Installing required packages..."
apt-get install -y curl wget git

# Get OpenVPN install script
log "Downloading OpenVPN install script..."
curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
chmod +x openvpn-install.sh

# Set environment variables for headless installation
export ENDPOINT=$(curl -4 ifconfig.co)
export AUTO_INSTALL=y
export APPROVE_INSTALL=y
export APPROVE_IP=y
export IPV6_SUPPORT=n
export PORT_CHOICE=1
export PROTOCOL_CHOICE=1
export DNS=11
export COMPRESSION_ENABLED=n
export CUSTOMIZE_ENC=n
export CLIENT=client
export PASS=1
export CONTINUE=y

# Run OpenVPN installation
log "Starting OpenVPN installation..."
./openvpn-install.sh

log "OpenVPN installation completed successfully!"

# Display status
log "OpenVPN service status:"
systemctl status openvpn@server --no-pager -l

log "OpenVPN configuration files are located in /root/"
log "To add new clients, run: /usr/local/bin/add-openvpn-client <client_name>"
log "To check status, run: /usr/local/bin/openvpn-status" 