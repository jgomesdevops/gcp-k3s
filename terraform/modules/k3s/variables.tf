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
  default = [
    "roles/artifactregistry.reader",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/compute.osLogin",
    "roles/iap.tunnelResourceAccessor"
  ]
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

# Tags and Labels
variable "instance_tags" {
  description = "Tags for the k3s instance"
  type        = list(string)
  default     = ["k3s-master"]
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default = {
    environment = "production"
    managed-by  = "terraform"
    project     = "k3s-cluster"
  }
}

variable "github_sha" {
  description = "GitHub SHA"
  type        = string
  default     = "latest"
}

variable "user_emails" {
  description = "List of user emails who can access the VM via IAP"
  type        = list(string)
}