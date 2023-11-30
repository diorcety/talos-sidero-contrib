locals {
  controlplane_nodes = flatten([for s in module.controlplanes : [for ip in s.internal_ips : { "ip" = ip, "name" : s.names[index(s.internal_ips, ip)] }]])
  k8s_cidr           = var.rules_k8s_cidr != null ? [var.rules_k8s_cidr] : []
  talos_cidr         = var.rules_talos_cidr != null ? [var.rules_talos_cidr] : []
}

resource "openstack_lb_loadbalancer_v2" "lb" {
  name                  = "${var.cluster_name}-lb"
  loadbalancer_provider = var.lb_provider

  vip_network_id = openstack_networking_network_v2.net.id
  vip_address    = local.internal_ip

  admin_state_up = "true"

  depends_on = [
    openstack_networking_subnet_v2.lb
  ]
}

resource "openstack_networking_floatingip_v2" "external" {
  pool    = var.floating_pool
  port_id = openstack_lb_loadbalancer_v2.lb.vip_port_id

  depends_on = [
    openstack_networking_router_interface_v2.lb
  ]
}

resource "openstack_lb_listener_v2" "k8s" {
  name                = "k8s"
  protocol            = "TCP"
  protocol_port       = 6443
  loadbalancer_id     = openstack_lb_loadbalancer_v2.lb.id
  allowed_cidrs       = local.k8s_cidr
  timeout_client_data = 2 * 60 * 1000
  timeout_member_data = 2 * 60 * 1000
}

resource "openstack_lb_pool_v2" "k8s" {
  name        = "k8s"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.k8s.id
}

resource "openstack_lb_monitor_v2" "k8s" {
  name             = "k8s"
  pool_id          = openstack_lb_pool_v2.k8s.id
  type             = "TLS-HELLO"
  delay            = 2
  timeout          = 2
  max_retries      = 1
  max_retries_down = 5
}

resource "openstack_lb_members_v2" "k8s" {
  pool_id = openstack_lb_pool_v2.k8s.id

  dynamic "member" {
    for_each = local.controlplane_nodes
    content {
      name          = member.value.name
      address       = member.value.ip
      protocol_port = 6443
    }
  }
}


resource "openstack_lb_listener_v2" "talos" {
  name            = "talos"
  protocol        = "TCP"
  protocol_port   = 50000
  loadbalancer_id = openstack_lb_loadbalancer_v2.lb.id
  allowed_cidrs   = local.talos_cidr
}

resource "openstack_lb_pool_v2" "talos" {
  name        = "talos"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.talos.id
}

resource "openstack_lb_monitor_v2" "talos" {
  name             = "talos"
  pool_id          = openstack_lb_pool_v2.talos.id
  type             = "TLS-HELLO"
  delay            = 2
  timeout          = 2
  max_retries      = 1
  max_retries_down = 5
}

resource "openstack_lb_members_v2" "talos" {
  pool_id = openstack_lb_pool_v2.talos.id

  dynamic "member" {
    for_each = local.controlplane_nodes
    content {
      name          = member.value.name
      address       = member.value.ip
      protocol_port = 50000
    }
  }
}
