# VPC Network
resource "google_compute_network" "this" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Subnet for k3s cluster
resource "google_compute_subnetwork" "this" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  network       = google_compute_network.this.id
  region        = var.gcp_region
}

# Cloud Router for NAT
resource "google_compute_router" "this" {
  name    = var.router_name
  region  = var.gcp_region
  network = google_compute_network.this.id
}

# Cloud NAT for outbound internet access
resource "google_compute_router_nat" "this" {
  name                               = var.nat_name
  router                             = google_compute_router.this.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
} 