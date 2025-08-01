# Service account for user access to VM via IAP
resource "google_service_account" "user_access" {
  account_id   = "user-access-sa-vm"
  display_name = "User Access Service Account"
  description  = "Service account for user access to VM via IAP"
}

# IAM roles for user access service account - READ ONLY
resource "google_project_iam_member" "user_access_iap" {
  project = var.gcp_project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "serviceAccount:${google_service_account.user_access.email}"
}

resource "google_project_iam_member" "user_access_compute_viewer" {
  project = var.gcp_project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.user_access.email}"
}

resource "google_project_iam_member" "user_access_oslogin" {
  project = var.gcp_project_id
  role    = "roles/compute.osLogin"
  member  = "serviceAccount:${google_service_account.user_access.email}"
}

resource "google_project_iam_member" "user_access_service_account_user" {
  project = var.gcp_project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.user_access.email}"
}

# Allow multiple users to impersonate the service account
resource "google_service_account_iam_binding" "user_impersonation_conditional" {
  service_account_id = google_service_account.user_access.name
  role               = "roles/iam.serviceAccountTokenCreator"

  members = [for email in var.user_emails : "user:${email}"]
} 