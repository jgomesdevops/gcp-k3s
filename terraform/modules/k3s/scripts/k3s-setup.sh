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
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.29.0+k3s1 INSTALL_K3S_EXEC="--disable traefik" sh - || echo "k3s installation failed"

# Wait for k3s to be ready
echo "Waiting for K3s to be ready..."
sleep 10

# Set KUBECONFIG environment variable
echo "Setting KUBECONFIG environment variable..."
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml


# Configure containerd for Artifact Registry using service account key
echo "Configuring containerd for Artifact Registry..."
GCP_REGION=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/gcp-region 2>/dev/null)
GCP_PROJECT_ID=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/gcp-project-id 2>/dev/null)
SA_KEY=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/sa-key 2>/dev/null | tr -d '\n')
GITHUB_SHA=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/github-sha 2>/dev/null)

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

# Wait for k3s to be fully ready before installing Kyverno
echo "Waiting for k3s to be fully ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s || echo "Nodes not ready yet"

echo "k3S setup completed successfully!"

# Install Helm
echo "Installing Helm..."
curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar xz
sudo mv linux-amd64/helm /usr/local/bin/
rm -rf linux-amd64

# Install ArgoCD
echo "Installing ArgoCD..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Change ArgoCD server service to NodePort
echo "Configuring ArgoCD server service to NodePort..."
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort","ports":[{"name":"http","port":80,"targetPort":8080,"nodePort":30080,"protocol":"TCP"},{"name":"https","port":443,"targetPort":8080,"nodePort":30443,"protocol":"TCP"}]}}'

# Download and configure ArgoCD Application with dynamic values
echo "Configuring ArgoCD Application with dynamic values..."
curl -s https://raw.githubusercontent.com/jgomesdevops/gcp-k3s/main/yaml/node-app.yaml -o /tmp/node-app.yaml

# Use sed to replace variables with actual values
sed -i \
    -e "s|thisregion-docker.pkg.dev/thisid|${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}|g" \
    -e "s|tag: \"latest\"|tag: \"${GITHUB_SHA}\"|g" \
    /tmp/node-app.yaml

# Apply the ArgoCD Application
kubectl apply -f /tmp/node-app.yaml

echo "Node Application Deployed Successfully!"

# Install readonly service account before Kyverno
echo "Installing readonly service account before Kyverno..."
kubectl apply -f https://raw.githubusercontent.com/jgomesdevops/gcp-k3s/main/yaml/readonly-sa.yaml
echo "Readonly service account installed successfully!"

# Download and deploy Kyverno via ArgoCD
echo "Configuring Kyverno ArgoCD Application..."
curl -s https://raw.githubusercontent.com/jgomesdevops/gcp-k3s/main/yaml/kyverno.yaml -o /tmp/kyverno-app.yaml

# Apply the Kyverno ArgoCD Application
kubectl apply -f /tmp/kyverno-app.yaml

echo "Kyverno Application deployed successfully!"

# Wait for Kyverno to be ready
echo "Waiting for Kyverno to be ready..."
sleep 60

# Download and configure Kyverno policy with dynamic values
echo "Configuring Kyverno policy with dynamic values..."
curl -s https://raw.githubusercontent.com/jgomesdevops/gcp-k3s/main/yaml/kyverno-policy.yaml -o /tmp/kyverno-policy.yaml

# Use sed to replace variables with actual values
sed -i \
    -e "s|thisregion-docker.pkg.dev/thisid|${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}|g" \
    /tmp/kyverno-policy.yaml

# Apply the Kyverno policy
kubectl apply -f /tmp/kyverno-policy.yaml

echo "Kyverno policy deployed successfully!"

# Install readonly service account after Kyverno
echo "Installing readonly service account after Kyverno..."
kubectl apply -f https://raw.githubusercontent.com/jgomesdevops/gcp-k3s/main/yaml/readonly-sa.yaml
echo "Readonly service account installed successfully after Kyverno!"

# Generate readonly kubeconfig for all users
echo "Generating readonly kubeconfig..."
curl -s https://raw.githubusercontent.com/jgomesdevops/gcp-k3s/main/yaml/readonly-kubeconfig-template.yaml -o /tmp/readonly-kubeconfig-template.yaml

# Get cluster information
CLUSTER_CA=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
CLUSTER_SERVER=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.server}')
READONLY_TOKEN=$(kubectl create token readonly-sa -n default)

# Use sed to replace placeholders with actual values
sed -i \
    -e "s|CLUSTER_SERVER_PLACEHOLDER|${CLUSTER_SERVER}|g" \
    -e "s|CLUSTER_CA_PLACEHOLDER|${CLUSTER_CA}|g" \
    -e "s|READONLY_TOKEN_PLACEHOLDER|${READONLY_TOKEN}|g" \
    /tmp/readonly-kubeconfig-template.yaml

# Copy the generated kubeconfig to a shared location
cp /tmp/readonly-kubeconfig-template.yaml /home/readonly-kubeconfig.yaml
chmod 644 /home/readonly-kubeconfig.yaml

echo "Readonly kubeconfig generated at /home/readonly-kubeconfig.yaml"
echo "Users can copy this file to ~/.kube/config for readonly access"

echo "Readonly access setup completed for all users!"

# Verify installations
echo "Verifying installations..."
which k3s || echo "k3s not found"
which kubectl || echo "kubectl not found"
which helm || echo "Helm not found"

echo "Setup script finished." 