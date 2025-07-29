# Firewall rule for internal communication
resource "google_compute_firewall" "internal" {
  name    = var.internal_firewall_name
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["6443", "10250", "2379", "2380", "10251", "10252"]
  }

  allow {
    protocol = "udp"
    ports    = ["8472", "51820"]
  }

  source_ranges = [var.subnet_cidr]
}

# Firewall rule for SSH access (restricted to IAP)
resource "google_compute_firewall" "ssh" {
  name    = var.ssh_firewall_name
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"] # IAP tunnel IPs
}

# Firewall rule for application access via NodePort
resource "google_compute_firewall" "app" {
  name    = var.app_firewall_name
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = [tostring(var.app_nodeport)]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = var.instance_tags
}

# Firewall rule for load balancer health checks
resource "google_compute_firewall" "lb_health_check" {
  name    = var.lb_health_check_firewall_name
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = [tostring(var.health_check_port)]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"] # Google Cloud Load Balancer health check IPs
  target_tags   = var.instance_tags
}

# Firewall rule for HTTP traffic to load balancer
resource "google_compute_firewall" "lb_http" {
  name    = var.lb_http_firewall_name
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = [tostring(var.load_balancer_port)]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = var.instance_tags
}

# Firewall rule for HTTPS traffic to load balancer
resource "google_compute_firewall" "lb_https" {
  name    = var.lb_https_firewall_name
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = var.instance_tags
} 