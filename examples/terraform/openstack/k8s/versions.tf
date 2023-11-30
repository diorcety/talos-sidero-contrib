# TF setup

terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "1.53.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.12.1"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = var.kubernetes_client_configuration.host
    cluster_ca_certificate = base64decode(var.kubernetes_client_configuration.ca_certificate)
    client_certificate     = base64decode(var.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(var.kubernetes_client_configuration.client_key)
  }
}
