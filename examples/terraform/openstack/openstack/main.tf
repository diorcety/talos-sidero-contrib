locals {
  external_ip            = openstack_networking_floatingip_v2.external.address
  internal_ip            = cidrhost(var.subnet_lb_cidr, 4)
  controlplane_endpoints = flatten([for s in module.controlplanes : [for ip in s.internal_ips : ip]])
  worker_endpoints       = flatten([for s in module.workers : [for ip in s.internal_ips : ip]])

  k8s_patches = concat([
    file("${path.module}/patches/common_patch.yaml")
    ],
    var.k8s_cilium ? [
      file("${path.module}/patches/cilium.yaml")
    ] : [],
    var.k8s_metrics ? [
      file("${path.module}/patches/metrics.yaml")
    ] : [],
    var.k8s_ccm ? [
      file("${path.module}/patches/ccm_patch.yaml")
    ] : []
  )
}

# Create custom image
resource "openstack_images_image_v2" "image" {
  name = "Talos Linux ${var.talos_version}"

  #image_source_url = "https://github.com/siderolabs/talos/releases/download/${var.talos_version}/openstack-amd64.raw.xz"
  #web_download     = true
  local_file_path  = "openstack-amd64.raw"
  container_format = "bare"
  disk_format      = "raw"

  visibility = "private"
  protected  = true

  lifecycle {
    ignore_changes = all
  }
}

data "openstack_images_image_v2" "image" {
  name        = "Talos Linux ${var.talos_version}"
  most_recent = true
  depends_on = [
    openstack_images_image_v2.image
  ]
}

# control plane nodes

module "controlplanes" {
  source = "./node"

  for_each = {
    for controlplane in var.controlplanes :
    controlplane.name => controlplane
  }

  is_controlplane = true

  name          = "${var.cluster_name}-${each.value.name}"
  talos_version = var.talos_version

  availability_zones = coalesce(each.value.availability_zones, [])
  flavor_name        = each.value.flavor_name
  nodes_count        = each.value.nodes_count

  user_data = data.talos_machine_configuration.controlplane.machine_configuration

  image_name = data.openstack_images_image_v2.image.name

  network_id  = openstack_networking_network_v2.net.id
  subnet_id   = openstack_networking_subnet_v2.controlplanes.id
  secgroup_id = openstack_networking_secgroup_v2.controlplanes.id

  keypair_name = openstack_compute_keypair_v2.key.name

  depends_on = [
    openstack_lb_listener_v2.k8s
  ]
}

# Work nodes

module "workers" {
  source = "./node"

  for_each = {
    for worker in var.workers :
    worker.name => worker
  }

  is_controlplane = false

  name          = "${var.cluster_name}-${each.value.name}"
  talos_version = var.talos_version

  availability_zones = coalesce(each.value.availability_zones, [])
  flavor_name        = each.value.flavor_name
  nodes_count        = each.value.nodes_count

  user_data = data.talos_machine_configuration.worker.machine_configuration

  image_name = data.openstack_images_image_v2.image.name

  keypair_name = openstack_compute_keypair_v2.key.name

  network_id  = openstack_networking_network_v2.net.id
  subnet_id   = openstack_networking_subnet_v2.workers.id
  secgroup_id = openstack_networking_secgroup_v2.workers.id

  depends_on = [
    openstack_lb_listener_v2.k8s
  ]
}

## Bootstrap talos

resource "talos_machine_secrets" "machine_secrets" {
  talos_version = var.talos_version
}

data "talos_client_configuration" "talosconfig" {

  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoints            = [local.external_ip]
  nodes                = flatten([local.controlplane_endpoints, local.worker_endpoints])
}

data "talos_machine_configuration" "controlplane" {
  talos_version = var.talos_version

  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${local.external_ip}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets

  kubernetes_version = var.kubernetes_version

  config_patches = concat([
    templatefile("${path.module}/patches/controlplane_patch.yaml", {
      loadbalancerip = local.external_ip
    })],
    local.k8s_patches
  )

  depends_on = [openstack_lb_loadbalancer_v2.lb]
}

resource "talos_machine_configuration_apply" "controlplane" {
  count = length(local.controlplane_endpoints)

  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration

  endpoint = local.external_ip
  node     = local.controlplane_endpoints[count.index]
}

data "talos_machine_configuration" "worker" {
  talos_version = var.talos_version

  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${local.external_ip}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets

  kubernetes_version = var.kubernetes_version

  config_patches = local.k8s_patches
}

resource "talos_machine_configuration_apply" "worker" {
  count = length(local.worker_endpoints)

  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration

  endpoint = local.external_ip
  node     = local.worker_endpoints[count.index]
}

resource "talos_machine_bootstrap" "bootstrap" {
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration

  endpoint = local.external_ip
  node     = local.controlplane_endpoints[0]
}

resource "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on = [talos_machine_bootstrap.bootstrap]

  client_configuration = talos_machine_secrets.machine_secrets.client_configuration

  endpoint = local.external_ip
  node     = local.controlplane_endpoints[0]
}
