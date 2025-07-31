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
    ports    = ["22","30000","30080","30443"]
  }

  source_ranges = ["35.235.240.0/20"] # IAP tunnel IPs
} 