output "k3s_master_ip" {
  description = "Internal IP address of the k3s master node"
  value       = google_compute_instance.this.network_interface[0].network_ip
}

output "application_access" {
  description = "How to access the application"
  value       = "Access via IAP tunnel: gcloud compute ssh --tunnel-through-iap ${google_compute_instance.this.name} --zone=${var.gcp_zone}"
}

output "vpc_name" {
  description = "Name of the VPC"
  value       = google_compute_network.this.name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.this.name
}

output "service_account_email" {
  description = "Email of the service account"
  value       = google_service_account.this.email
}

output "instance_name" {
  description = "Name of the k3s instance"
  value       = google_compute_instance.this.name
}
