
variable "talos_version" {
  description = "Talos version to deploy"
  type        = string
  default     = "v1.5.5"
}

variable "name" {
  type = string
}

variable "nodes_count" {
  type = string
}

variable "flavor_name" {
  type = string
}

variable "image_name" {
  type = string
}

variable "is_controlplane" {
  type = bool
}

variable "availability_zones" {
  type = list(string)
}

variable "region" {
  type    = string
  default = null
}

variable "secgroup_id" {
  type = string
}

variable "network_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "keypair_name" {
  type = string
}

variable "user_data" {
  type    = string
  default = null
}
