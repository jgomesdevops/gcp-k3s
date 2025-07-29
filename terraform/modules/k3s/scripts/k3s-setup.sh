#!/bin/bash

# Exit on any error
set -e

echo "Starting k3s setup script..."

# Update system (ignore repository errors)
apt-get update 
apt-get upgrade -y

# Install required packages
apt-get install -y curl wget git ca-certificates gnupg lsb-release

# Disable UFW firewall
echo "Disabling UFW firewall..."
ufw disable

# Install K3s
echo "Installing K3s..."
curl -sfL https://get.k3s.io | sh - || echo "k3s installation failed"

# Wait for k3s to be ready
echo "Waiting for K3s to be ready..."
sleep 10

# Configure containerd for Artifact Registry using service account key
echo "Configuring containerd for Artifact Registry..."
GCP_REGION=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/gcp-region 2>/dev/null || echo "europe-west1")
SA_KEY=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/sa-key 2>/dev/null | tr -d '\n')

# Create containerd config directory if it doesn't exist
mkdir -p /etc/rancher/k3s

# Configure containerd to use service account key for Artifact Registry
cat > /etc/rancher/k3s/registries.yaml <<EOF
configs:
  ${GCP_REGION}-docker.pkg.dev:
    auth:
      username: _json_key
      password: '${SA_KEY}'
mirrors:
  ${GCP_REGION}-docker.pkg.dev:
    endpoint:
      - "https://${GCP_REGION}-docker.pkg.dev"
EOF

# Restart k3s to pick up the new registry configuration
systemctl restart k3s || echo "Failed to restart k3s"

# Install Helm
echo "Installing Helm..."
curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar xz
sudo mv linux-amd64/helm /usr/local/bin/
rm -rf linux-amd64

echo "k3s setup completed successfully!"

# Verify installations
echo "Verifying installations..."
which k3s || echo "k3s not found"
which kubectl || echo "kubectl not found"
which helm || echo "Helm not found"

echo "Setup script finished." 