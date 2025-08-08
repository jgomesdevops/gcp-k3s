plugin "google" {
  enabled = true
  source  = "github.com/terraform-linters/tflint-ruleset-google"
  version = "0.30.0"
}

# Uncomment to enable the Terraform community ruleset as well
plugin "terraform" {
   enabled = true
   source  = "github.com/terraform-linters/tflint-ruleset-terraform"
   version = "0.13.0"
}

config {
  call_module_type = "local"
}


