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

variable "instance_name" {
  description = "Name of the instance"
  type        = string
  default     = "k3s"
}

variable "github_sha" {
  description = "GitHub SHA"
  type        = string
  default     = "latest"
}

# People allowed to impersonate the VM access service account
variable "user_emails" {
  description = "List of user emails who can access the VM via IAP"
  type        = list(string)
  default     = ["jgomesdevops@gmail.com"]
}
