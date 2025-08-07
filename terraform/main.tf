# K3S Cluster Module
module "k3s_cluster" {
  source = "./modules/k3s"

  # Required variables
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
  gcp_zone       = var.gcp_zone

  # Network configuration
  vpc_name    = "this"
  subnet_name = "this-subnet"
  subnet_cidr = "10.0.0.0/24"

  # Compute configuration
  instance_name  = var.instance_name
  machine_type   = "e2-medium"
  disk_size_gb   = 20
  disk_image     = "ubuntu-os-cloud/ubuntu-2204-lts"
  enable_oslogin = true
  github_sha     = var.github_sha

  # Service account configuration
  service_account_name         = "this-sa"
  service_account_display_name = "K3S Service Account"
  service_account_description  = "K3S Service Account"

  # User access configuration
  user_emails = [
    "jgomesdevops@gmail.com"
  ]

  # Labels and tags
  instance_tags = ["this"]
  labels = {
    managed-by = "terraform"
    project    = "gcp-k3s"
    team       = "devops"
  }

  # OpenVPN configuration
  enable_openvpn                       = true
  openvpn_instance_name                = "openvpn-server"
  openvpn_machine_type                 = "e2-small"
  openvpn_disk_size_gb                 = 20
  openvpn_port                         = 1194
  openvpn_protocol                     = "udp"
  openvpn_firewall_name                = "openvpn-udp"
  openvpn_service_account_name         = "openvpn-sa"
  openvpn_service_account_display_name = "OpenVPN Service Account"
  openvpn_service_account_description  = "OpenVPN Service Account"
  openvpn_instance_tags                = ["openvpn-server"]
  openvpn_labels = {
    managed-by = "terraform"
    project    = "gcp-openvpn"
    team       = "devops"
  }
}
