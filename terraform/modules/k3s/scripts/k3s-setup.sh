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
helm install kyverno kyverno/kyverno \
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
cat <<EOF > /tmp/kyverno-policies.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: trusted-registry
  annotations:
    policies.kyverno.io/title: Require Trusted Registry
    policies.kyverno.io/category: Security
    policies.kyverno.io/severity: high
    policies.kyverno.io/subject: "Pod, Deployment, StatefulSet, Job, CronJob, DaemonSet"
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
      message: "Only containers from trusted registry are allowed. Allowed prefix: ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/"
      anyPattern:
      # For Deployments, StatefulSets, etc.
      - spec:
          template:
            spec:
              containers:
              - image: "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/*"
      - spec:
          template:
            spec:
              initContainers:
              - image: "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/*"
      - spec:
          template:
            spec:
              ephemeralContainers:
              - image: "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/*"
      # For standalone Pods
      - spec:
          containers:
          - image: "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/*"
      - spec:
          initContainers:
          - image: "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/*"
      - spec:
          ephemeralContainers:
          - image: "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/*"
EOF


kubectl apply -f /tmp/kyverno-policies.yaml

echo "k3s setup completed successfully!"

kubectl create namespace node-app --dry-run=client -o yaml | kubectl apply -f -

# Create deployment and service for Node.js application
cat > /tmp/node-app-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-app
  namespace: node-app
  labels:
    app: node-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: node-app
  template:
    metadata:
      labels:
        app: node-app
    spec:
      containers:
      - name: node-app
        image: ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/node-app-repo/node-app:${GITHUB_SHA}
        ports:
        - containerPort: 8080
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "8080"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: node-app-service
  namespace: node-app
  labels:
    app: node-app
spec:
  type: NodePort
  selector:
    app: node-app
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 30000
    protocol: TCP
  sessionAffinity: None
EOF

# Apply the deployment and service
kubectl apply -f /tmp/node-app-deployment.yaml

echo "Waiting for Node.js application deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/node-app -n node-app

# Verify installations
echo "Verifying installations..."
which k3s || echo "k3s not found"
which kubectl || echo "kubectl not found"
which helm || echo "Helm not found"

echo "Setup script finished." 