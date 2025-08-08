terraform {
  backend "gcs" {
    bucket = "gcp-k3s-terraform-state"
    prefix = "terraform/state"
  }
}