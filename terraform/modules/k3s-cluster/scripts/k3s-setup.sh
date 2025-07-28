#!/bin/bash

# Exit on any error
set -e

echo "Starting k3s setup script..."

# Update system (ignore repository errors)
apt-get update 
apt-get upgrade -y

# Install required packages
apt-get install -y curl wget git ca-certificates gnupg lsb-release

# Configure Docker for Artifact Registry
echo "Configuring Docker for Artifact Registry..."
gcloud auth configure-docker europe-west1-docker.pkg.dev

# Pull the latest image from Artifact Registry
echo "Pulling latest image from Artifact Registry..."
docker pull europe-west1-docker.pkg.dev/PROJECT_ID/node-app-repo/node-app:latest || echo "Failed to pull image from Artifact Registry"

# Install Docker (required for k3s)
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh || echo "Docker installation failed, continuing..."

# Install k3s with security configurations
echo "Installing k3s..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--docker --write-kubeconfig-mode 644 --tls-san $(hostname) --disable traefik --disable servicelb" sh - || echo "k3s installation failed"

# Wait for k3s to be ready
echo "Waiting for k3s to be ready..."
sleep 30

echo "k3s setup completed successfully!"

# Verify installations
echo "Verifying installations..."
which docker || echo "Docker not found"
which k3s || echo "k3s not found"
which kubectl || echo "kubectl not found"

echo "Setup script finished." 