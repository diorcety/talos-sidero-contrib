resource "openstack_networking_network_v2" "net" {
  name                  = "${var.cluster_name}-net"
  admin_state_up        = "true"
  port_security_enabled = "true"
}

resource "openstack_networking_subnet_v2" "controlplanes" {
  name            = "${var.cluster_name}-controlplanes-subnet"
  network_id      = openstack_networking_network_v2.net.id
  cidr            = var.subnet_controlplane_cidr
  ip_version      = 4
  dns_nameservers = var.dns_nameservers4
}

resource "openstack_networking_subnet_v2" "workers" {
  name            = "${var.cluster_name}-workers-subnet"
  network_id      = openstack_networking_network_v2.net.id
  cidr            = var.subnet_agents_cidr
  ip_version      = 4
  dns_nameservers = var.dns_nameservers4
}

resource "openstack_networking_subnet_v2" "lb" {
  name            = "${var.cluster_name}-lb-subnet"
  network_id      = openstack_networking_network_v2.net.id
  cidr            = var.subnet_lb_cidr
  ip_version      = 4
  dns_nameservers = var.dns_nameservers4
}

data "openstack_networking_network_v2" "floating_net" {
  name = var.floating_pool
}

resource "openstack_networking_router_v2" "router" {
  name                = "${var.cluster_name}-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.floating_net.id
}

resource "openstack_networking_router_interface_v2" "controlplanes" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.controlplanes.id
}

resource "openstack_networking_router_interface_v2" "workers" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.workers.id
}

resource "openstack_networking_router_interface_v2" "lb" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.lb.id
}
