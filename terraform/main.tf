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
  machine_type   = "e2-small"
  disk_size_gb   = 20
  disk_image     = "ubuntu-os-cloud/ubuntu-2204-lts"
  enable_oslogin = true

  # Service account configuration
  service_account_name         = "this-sa"
  service_account_display_name = "K3S Service Account"
  service_account_description  = "K3S Service Account"

  # Load balancer configuration
  enable_load_balancer = true
  load_balancer_port   = 80
  app_nodeport         = 30000
  health_check_path    = "/health"
  health_check_port    = 30000

  # Labels and tags
  instance_tags = ["this"]
  labels = {
    managed-by = "terraform"
    project    = "gcp-k3s"
    team       = "devops"
  }

  artifact_registry_repository_id = "node-app-repo"
}
