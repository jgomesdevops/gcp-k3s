# Service account for k3s VM
resource "google_service_account" "this" {
  account_id   = var.service_account_name
  display_name = var.service_account_display_name
  description  = var.service_account_description
}

# IAM role for k3s service account
resource "google_project_iam_member" "this" {
  for_each = toset(var.service_account_roles)

  project = var.gcp_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.this.email}"
}

# Create service account key
resource "google_service_account_key" "this" {
  service_account_id = google_service_account.this.name
}

# k3s VM instance
resource "google_compute_instance" "this" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = var.disk_image
      size  = var.disk_size_gb
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.this.id
    # No public IP - private only
  }

  service_account {
    email  = google_service_account.this.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = var.enable_oslogin ? "TRUE" : "FALSE"
    gcp-region     = var.gcp_region
    gcp-project-id = var.gcp_project_id
    sa-key         = base64decode(google_service_account_key.this.private_key)
    github-sha     = var.github_sha
  }

  metadata_startup_script = file("${path.module}/scripts/k3s-setup.sh")

  tags = var.instance_tags

  labels = var.labels
}

# OpenVPN Service Account
resource "google_service_account" "openvpn" {
  count = var.enable_openvpn ? 1 : 0

  account_id   = var.openvpn_service_account_name
  display_name = var.openvpn_service_account_display_name
  description  = var.openvpn_service_account_description
}

# IAM role for OpenVPN service account
resource "google_project_iam_member" "openvpn" {
  for_each = var.enable_openvpn ? toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/compute.osLogin",
    "roles/iap.tunnelResourceAccessor"
  ]) : toset([])

  project = var.gcp_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.openvpn[0].email}"
}

# Create OpenVPN service account key
resource "google_service_account_key" "openvpn" {
  count = var.enable_openvpn ? 1 : 0

  service_account_id = google_service_account.openvpn[0].name
}

# OpenVPN VM instance
resource "google_compute_instance" "openvpn" {
  count = var.enable_openvpn ? 1 : 0

  name         = var.openvpn_instance_name
  machine_type = var.openvpn_machine_type
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = var.disk_image
      size  = var.openvpn_disk_size_gb
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.this.id
    access_config {
      # Ephemeral public IP
    }
  }

  service_account {
    email  = google_service_account.openvpn[0].email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin = var.enable_oslogin ? "TRUE" : "FALSE"
  }

  metadata_startup_script = file("${path.module}/scripts/openvpn-setup.sh")

  tags = var.openvpn_instance_tags

  labels = var.openvpn_labels
} 