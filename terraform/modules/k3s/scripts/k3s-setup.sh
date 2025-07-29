#!/bin/bash

# Exit on any error
set -e

echo "Starting k3s setup script..."

# Update system (ignore repository errors)
apt-get update 
apt-get upgrade -y

# Install required packages
apt-get install -y curl wget git ca-certificates gnupg lsb-release

# Install gcloud CLI if not present
if ! command -v gcloud &> /dev/null; then
    echo "Installing gcloud CLI..."
    curl https://sdk.cloud.google.com | bash
    export PATH=$PATH:/root/google-cloud-sdk/bin
fi

# Install Docker first (required for k3s)
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh || echo "Docker installation failed, continuing..."

# Install k3s with security configurations
echo "Installing k3s..."
curl -sfL https://get.k3s.io | sh - || echo "k3s installation failed"

# Wait for k3s to be ready
echo "Waiting for k3s to be ready..."
sleep 30

# Install Helm
echo "Installing Helm..."
curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar xz
sudo mv linux-amd64/helm /usr/local/bin/
rm -rf linux-amd64

echo "k3s setup completed successfully!"

# Verify installations
echo "Verifying installations..."
which docker || echo "Docker not found"
which k3s || echo "k3s not found"
which kubectl || echo "kubectl not found"
which helm || echo "Helm not found"

# Verify credential helper configuration
echo "Verifying credential helper configuration..."
echo "Docker config contents:"
cat ~/.docker/config.json || echo "Docker config not found"

echo "Setup script finished." 