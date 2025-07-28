output "k3s_master_ip" {
  description = "Internal IP address of the k3s master node"
  value       = google_compute_instance.this.network_interface[0].network_ip
}

output "application_access" {
  description = "How to access the application"
  value       = "Access via NodePort: http://VM_INTERNAL_IP:${var.app_nodeport} (use gcloud compute ssh to connect first)"
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${google_compute_instance.this.network_interface[0].network_ip}:${var.app_nodeport}"
}

output "public_load_balancer_ip" {
  description = "Public IP address of the load balancer"
  value       = var.enable_load_balancer ? google_compute_global_address.this[0].address : null
}

output "public_application_url" {
  description = "Public URL to access the application via load balancer"
  value       = var.enable_load_balancer ? "http://${google_compute_global_address.this[0].address}" : null
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

output "artifact_registry_repository" {
  description = "Artifact Registry repository name"
  value       = google_artifact_registry_repository.this.name
}

output "artifact_registry_location" {
  description = "Artifact Registry repository location"
  value       = google_artifact_registry_repository.this.location
} 