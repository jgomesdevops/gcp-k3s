output "k3s_master_ip" {
  description = "Internal IP address of the k3s master node"
  value       = module.k3s_cluster.k3s_master_ip
}

output "application_access" {
  description = "How to access the application"
  value       = module.k3s_cluster.application_access
}

output "vpc_name" {
  description = "Name of the VPC"
  value       = module.k3s_cluster.vpc_name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = module.k3s_cluster.subnet_name
}

output "service_account_email" {
  description = "Email of the service account"
  value       = module.k3s_cluster.service_account_email
}

output "instance_name" {
  description = "Name of the k3s instance"
  value       = module.k3s_cluster.instance_name
}
