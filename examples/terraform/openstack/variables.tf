# Global

variable "cluster_name" {
  description = "Name of cluster"
  type        = string
  default     = "talos"
}

variable "talos_version" {
  description = "Talos version to deploy"
  type        = string
  default     = "v1.6.0"
}

variable "ssh_authorized_keys" {
  type    = list(string)
  default = ["~/.ssh/id_rsa.pub"]
}

# Networking

variable "lb_provider" {
  type     = string
  default  = "amphora"
  nullable = false
}

variable "dns_nameservers4" {
  type = list(string)
  # Cloudflare
  default = ["9.9.9.9", "4.4.4.4"]
}

variable "subnet_controlplane_cidr" {
  type    = string
  default = "192.168.42.0/24"
}

variable "subnet_agents_cidr" {
  type    = string
  default = "192.168.43.0/24"
}

variable "subnet_lb_cidr" {
  type    = string
  default = "192.168.44.0/24"
}

variable "floating_pool" {
  type = string
}

variable "rules_talos_cidr" {
  type = string
  validation {
    condition     = can(cidrnetmask(var.rules_talos_cidr)) || var.rules_talos_cidr == null
    error_message = "Must be a valid IPv4 CIDR block or null (no access)"
  }
}

variable "rules_k8s_cidr" {
  type = string
  validation {
    condition     = can(cidrnetmask(var.rules_k8s_cidr)) || var.rules_k8s_cidr == null
    error_message = "Must be a valid IPv4 CIDR block or null (no access)"
  }
}
variable "controlplanes" {
  type = list(object({
    name               = string
    flavor_name        = string
    region             = optional(string)
    nodes_count        = number
    availability_zones = optional(list(string))
  }))
}

variable "workers" {
  type = list(object({
    name               = string
    flavor_name        = string
    region             = optional(string)
    nodes_count        = number
    availability_zones = optional(list(string))
  }))
}

variable "k8s_cilium" {
  type = bool
  default = true
}

variable "k8s_ccm" {
  type = bool
  default = true
}

variable "k8s_csi" {
  type = bool
  default = true
}

variable "k8s_metrics" {
  type = bool
  default = true
}

variable "k8s_nginx" {
  type    = bool
  default = true
}