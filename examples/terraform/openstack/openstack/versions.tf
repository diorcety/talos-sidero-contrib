# TF setup

terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.53.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.3.4"
    }
  }
}

# Configure providers
provider "openstack" {
  use_octavia = true
}
