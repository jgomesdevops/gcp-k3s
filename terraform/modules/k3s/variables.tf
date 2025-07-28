# Required Variables
variable "gcp_project_id" {
  description = "Google Cloud Project ID"
  type        = string
}

variable "gcp_region" {
  description = "Google Cloud Region"
  type        = string
  default     = "europe-west1"
}

variable "gcp_zone" {
  description = "Google Cloud Zone"
  type        = string
  default     = "europe-west1-b"
}

# Network Variables
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "k3s-vpc"
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "k3s-subnet"
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "router_name" {
  description = "Name of the Cloud Router"
  type        = string
  default     = "k3s-router"
}

variable "nat_name" {
  description = "Name of the Cloud NAT"
  type        = string
  default     = "k3s-nat"
}

# Compute Variables
variable "instance_name" {
  description = "Name of the k3s instance"
  type        = string
  default     = "k3s-master"
}

variable "machine_type" {
  description = "Machine type for the k3s instance"
  type        = string
  default     = "e2-small"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
}

variable "disk_image" {
  description = "Boot disk image"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "enable_oslogin" {
  description = "Enable OS Login"
  type        = bool
  default     = true
}

# Service Account Variables
variable "service_account_name" {
  description = "Name of the service account"
  type        = string
  default     = "k3s-service-account"
}

variable "service_account_display_name" {
  description = "Display name of the service account"
  type        = string
  default     = "k3s Service Account"
}

variable "service_account_description" {
  description = "Description of the service account"
  type        = string
  default     = "Service Account for K3S Cluster"
}

variable "service_account_roles" {
  description = "List of IAM roles to assign to the service account"
  type        = list(string)
  default     = [
    "roles/compute.instanceAdmin.v1",
    "roles/storage.admin",
    "roles/compute.osAdminLogin"
  ]
}

# Load Balancer Variables
variable "enable_load_balancer" {
  description = "Enable public load balancer"
  type        = bool
  default     = true
}

variable "load_balancer_name" {
  description = "Name of the load balancer"
  type        = string
  default     = "app-global-forwarding-rule"
}

variable "load_balancer_port" {
  description = "Port for the load balancer"
  type        = number
  default     = 80
}

variable "app_nodeport" {
  description = "NodePort for the application"
  type        = number
  default     = 30000
}

variable "health_check_path" {
  description = "Health check path for the application"
  type        = string
  default     = "/health"
}

variable "health_check_port" {
  description = "Health check port"
  type        = number
  default     = 30000
}

# Firewall Variables
variable "internal_firewall_name" {
  description = "Name of the internal firewall rule"
  type        = string
  default     = "k3s-internal"
}

variable "ssh_firewall_name" {
  description = "Name of the SSH firewall rule"
  type        = string
  default     = "k3s-ssh"
}

variable "app_firewall_name" {
  description = "Name of the application firewall rule"
  type        = string
  default     = "app-nodeport"
}

variable "lb_health_check_firewall_name" {
  description = "Name of the load balancer health check firewall rule"
  type        = string
  default     = "lb-health-check"
}

variable "lb_http_firewall_name" {
  description = "Name of the HTTP firewall rule"
  type        = string
  default     = "lb-http"
}

variable "lb_https_firewall_name" {
  description = "Name of the HTTPS firewall rule"
  type        = string
  default     = "lb-https"
}

# Tags and Labels
variable "instance_tags" {
  description = "Tags for the k3s instance"
  type        = list(string)
  default     = ["k3s-master"]
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {
    environment = "production"
    managed-by  = "terraform"
    project     = "k3s-cluster"
  }
}

# Network Endpoint Group Variables
variable "neg_name" {
  description = "Name of the Network Endpoint Group"
  type        = string
  default     = "app-network-endpoint-group"
}

variable "backend_service_name" {
  description = "Name of the backend service"
  type        = string
  default     = "app-backend-service"
}

variable "health_check_name" {
  description = "Name of the health check"
  type        = string
  default     = "app-health-check"
}

variable "balancing_mode" {
  description = "Load balancing mode for the backend service"
  type        = string
  default     = "RATE"
}

variable "max_rate_per_endpoint" {
  description = "Maximum rate per endpoint"
  type        = number
  default     = 100
}

# Timeouts
variable "backend_service_timeout" {
  description = "Timeout for the backend service"
  type        = number
  default     = 10
}

# Artifact Registry Variables
variable "artifact_registry_repository_id" {
  description = "ID of the Artifact Registry repository"
  type        = string
  default     = "node-app-repo"
} 