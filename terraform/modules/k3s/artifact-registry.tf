# Artifact Registry for Docker images
resource "google_artifact_registry_repository" "this" {
  location      = var.gcp_region
  repository_id = var.artifact_registry_repository_id
  description   = "Docker repository for Node.js application"
  format        = "DOCKER"
}

# IAM binding for the service account to access Artifact Registry
resource "google_artifact_registry_repository_iam_member" "this" {
  location   = google_artifact_registry_repository.this.location
  repository = google_artifact_registry_repository.this.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.this.email}"
} 