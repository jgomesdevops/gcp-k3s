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
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.29.0+k3s1 INSTALL_K3S_EXEC="--disable traefik --write-kubeconfig-mode 644" sh - || echo "k3s installation failed"

# Wait for k3s to be ready
echo "Waiting for K3s to be ready..."
sleep 10

# Configure containerd for Artifact Registry using service account key
echo "Configuring containerd for Artifact Registry..."
GCP_REGION=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/gcp-region 2>/dev/null || echo "europe-west1")
GCP_PROJECT_ID=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/gcp-project-id 2>/dev/null || echo "default-project")
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

# Wait for k3s to be fully ready before installing Kyverno
echo "Waiting for k3s to be fully ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s || echo "Nodes not ready yet"

# Install Kyverno
echo "Installing Kyverno..."
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install --kubeconfig=/etc/rancher/k3s/k3s.yaml kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace \
  --set replicaCount=1 \
  --set admissionController.failurePolicy=Fail \
  --wait

# Wait a bit more for webhooks to be registered
echo "Waiting for Kyverno webhooks to be ready..."
sleep 30

# Apply Kyverno policies
echo "Applying Kyverno policies..."
cat > /tmp/kyverno-policies.yaml << EOF
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: trusted-registry
  annotations:
    policies.kyverno.io/title: Require Trusted Registry
    policies.kyverno.io/category: Security
    policies.kyverno.io/severity: high
    policies.kyverno.io/subject: Pod
    policies.kyverno.io/description: >-
      This policy ensures that only containers from the trusted GCP Artifact Registry are allowed to run.
spec:
  validationFailureAction: Enforce
  background: false
  rules:
  - name: check-trusted-registry
    match:
      any:
      - resources:
          kinds:
          - Pod
          - Deployment
          - StatefulSet
          - DaemonSet
          - CronJob
          - Job
    validate:
      message: "Only containers from trusted registry are allowed. Allowed registries: ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/*"
      pattern:
        spec:
          =(initContainers):
          - image: "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/*"
          =(ephemeralContainers):
          - image: "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/*"
          containers:
          - image: "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/*"
EOF

kubectl apply -f /tmp/kyverno-policies.yaml

echo "k3s setup completed successfully!"

# Verify installations
echo "Verifying installations..."
which k3s || echo "k3s not found"
which kubectl || echo "kubectl not found"
which helm || echo "Helm not found"

echo "Setup script finished." 