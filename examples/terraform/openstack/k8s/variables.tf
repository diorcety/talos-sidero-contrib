# Global

variable "cluster_name" {
  description = "Name of cluster"
  type        = string
  default     = "talos"
}

variable "lb_provider" {
  type     = string
  default  = "amphora"
  nullable = false
}

variable "lb_id" {
  type = string
}

variable "lb_network_id" {
  type = string
}

variable "lb_subnet_id" {
  type = string
}

variable "lb_floating_network_id" {
  type = string
}

variable "k8s_cilium" {
  type    = bool
  default = true
}

variable "k8s_ccm" {
  type    = bool
  default = true
}

variable "k8s_csi" {
  type    = bool
  default = true
}

variable "k8s_nginx" {
  type    = bool
  default = true
}

variable "kubernetes_client_configuration" {
  type = object({
    ca_certificate     = string
    client_certificate = string
    client_key         = string
    host               = string
  })
}
