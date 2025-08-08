# K3S Cluster Module
module "k3s_cluster" {
  source = "./modules/k3s"

  # Required variables
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  gcp_zone       = var.gcp_zone

  # Compute configuration
  instance_name = var.instance_name
  machine_type  = "e2-medium"
  github_sha    = var.github_sha

  # User access configuration
  user_emails = var.user_emails

  # OpenVPN configuration
  enable_openvpn = true
}
