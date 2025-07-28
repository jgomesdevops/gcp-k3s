variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
  default     = "europe-west1"
}

variable "gcp_zone" {
  description = "GCP Zone"
  type        = string
  default     = "europe-west1-b"
}

variable "vm_user" {
  description = "Default user for the VM (will be managed by OS Login)"
  type        = string
  default     = "debian"
} 