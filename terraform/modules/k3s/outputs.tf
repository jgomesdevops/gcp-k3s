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

# OpenVPN Outputs
output "openvpn_server_ip" {
  description = "Internal IP address of the OpenVPN server"
  value       = var.enable_openvpn ? google_compute_instance.openvpn[0].network_interface[0].network_ip : null
}

output "openvpn_external_ip" {
  description = "External IP address of the OpenVPN server"
  value       = var.enable_openvpn ? google_compute_instance.openvpn[0].network_interface[0].access_config[0].nat_ip : null
}

output "openvpn_access" {
  description = "How to access the OpenVPN server"
  value       = var.enable_openvpn ? "Access via IAP tunnel: gcloud compute ssh --tunnel-through-iap ${google_compute_instance.openvpn[0].name} --zone=${var.gcp_zone}" : null
}

output "openvpn_service_account_email" {
  description = "Email of the OpenVPN service account"
  value       = var.enable_openvpn ? google_service_account.openvpn[0].email : null
}

output "openvpn_instance_name" {
  description = "Name of the OpenVPN instance"
  value       = var.enable_openvpn ? google_compute_instance.openvpn[0].name : null
}

output "openvpn_port" {
  description = "OpenVPN port"
  value       = var.enable_openvpn ? var.openvpn_port : null
}

output "openvpn_protocol" {
  description = "OpenVPN protocol"
  value       = var.enable_openvpn ? var.openvpn_protocol : null
}
