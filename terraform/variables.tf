variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
}

variable "gcp_zone" {
  description = "GCP Zone"
  type        = string
}

variable "vm_user" {
  description = "Default user for the VM"
  type        = string
  default     = "debian"
}

variable "instance_name" {
  description = "Name of the instance"
  type        = string
}

variable "github_sha" {
  description = "GitHub SHA"
  type        = string
  default     = "latest"
}