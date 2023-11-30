resource "openstack_networking_secgroup_v2" "controlplanes" {
  name                 = "${var.cluster_name}-controlplanes"
  delete_default_rules = true
}

resource "openstack_networking_secgroup_v2" "workers" {
  name                 = "${var.cluster_name}-workers"
  delete_default_rules = true
}

resource "openstack_networking_secgroup_rule_v2" "lb" {
  for_each = {
    for rule in [
      { "port" : 6443, "protocol" : "tcp", "source" : var.subnet_lb_cidr },
      { "port" : 50000, "protocol" : "tcp", "source" : var.subnet_lb_cidr },
    ] :
    format("%s-%s-%s", rule["source"], rule["protocol"], rule["port"]) => rule
  }
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = each.value.protocol
  port_range_min    = each.value.port
  port_range_max    = each.value.port
  remote_ip_prefix  = each.value.source
  security_group_id = openstack_networking_secgroup_v2.controlplanes.id
}

resource "openstack_networking_secgroup_rule_v2" "controlplanes4" {
  direction         = "egress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.controlplanes.id
}

resource "openstack_networking_secgroup_rule_v2" "controlplanes6" {
  direction         = "egress"
  ethertype         = "IPv6"
  security_group_id = openstack_networking_secgroup_v2.controlplanes.id
}

resource "openstack_networking_secgroup_rule_v2" "workers4" {
  direction         = "egress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.workers.id
}

resource "openstack_networking_secgroup_rule_v2" "workers6" {
  direction         = "egress"
  ethertype         = "IPv6"
  security_group_id = openstack_networking_secgroup_v2.workers.id
}

resource "openstack_networking_secgroup_rule_v2" "default" {
  for_each = {
    for rule in [
      # etcd
      { "port" : 2379, "protocol" : "tcp", "from" : openstack_networking_secgroup_v2.controlplanes, "to" : openstack_networking_secgroup_v2.controlplanes },
      { "port" : 2380, "protocol" : "tcp", "from" : openstack_networking_secgroup_v2.controlplanes, "to" : openstack_networking_secgroup_v2.controlplanes },
      # api controlplane (k8s)
      { "port" : 6443, "protocol" : "tcp", "from" : openstack_networking_secgroup_v2.controlplanes, "to" : openstack_networking_secgroup_v2.controlplanes },
      { "port" : 6443, "protocol" : "tcp", "from" : openstack_networking_secgroup_v2.workers, "to" : openstack_networking_secgroup_v2.controlplanes },
      # prism
      { "port" : 7445, "protocol" : "tcp", "from" : openstack_networking_secgroup_v2.controlplanes, "to" : openstack_networking_secgroup_v2.controlplanes },
      { "port" : 7445, "protocol" : "tcp", "from" : openstack_networking_secgroup_v2.workers, "to" : openstack_networking_secgroup_v2.controlplanes },
      # talos supervisor
      { "port" : 50000, "protocol" : "tcp", "from" : openstack_networking_secgroup_v2.controlplanes, "to" : openstack_networking_secgroup_v2.controlplanes },
      { "port" : 50000, "protocol" : "tcp", "from" : openstack_networking_secgroup_v2.workers, "to" : openstack_networking_secgroup_v2.controlplanes },
      { "port" : 50000, "protocol" : "tcp", "from" : openstack_networking_secgroup_v2.controlplanes, "to" : openstack_networking_secgroup_v2.workers },
      { "port" : 50001, "protocol" : "tcp", "from" : openstack_networking_secgroup_v2.workers, "to" : openstack_networking_secgroup_v2.controlplanes },
      # cilium
      { "port" : 8472, "protocol" : "udp", "from" : openstack_networking_secgroup_v2.controlplanes, "to" : openstack_networking_secgroup_v2.controlplanes },
      { "port" : 8472, "protocol" : "udp", "from" : openstack_networking_secgroup_v2.workers, "to" : openstack_networking_secgroup_v2.controlplanes },
      { "port" : 8472, "protocol" : "udp", "from" : openstack_networking_secgroup_v2.controlplanes, "to" : openstack_networking_secgroup_v2.workers },
      { "port" : 8472, "protocol" : "udp", "from" : openstack_networking_secgroup_v2.workers, "to" : openstack_networking_secgroup_v2.workers },
      { "port" : 4240, "protocol" : "tcp", "from" : openstack_networking_secgroup_v2.controlplanes, "to" : openstack_networking_secgroup_v2.controlplanes },
      { "port" : 4240, "protocol" : "tcp", "from" : openstack_networking_secgroup_v2.workers, "to" : openstack_networking_secgroup_v2.controlplanes },
      { "port" : 4240, "protocol" : "tcp", "from" : openstack_networking_secgroup_v2.controlplanes, "to" : openstack_networking_secgroup_v2.workers },
      { "port" : 4240, "protocol" : "tcp", "from" : openstack_networking_secgroup_v2.workers, "to" : openstack_networking_secgroup_v2.workers },
      { "port" : 0, "protocol" : "icmp", "from" : openstack_networking_secgroup_v2.controlplanes, "to" : openstack_networking_secgroup_v2.controlplanes },
      { "port" : 0, "protocol" : "icmp", "from" : openstack_networking_secgroup_v2.workers, "to" : openstack_networking_secgroup_v2.controlplanes },
      { "port" : 0, "protocol" : "icmp", "from" : openstack_networking_secgroup_v2.controlplanes, "to" : openstack_networking_secgroup_v2.workers },
      { "port" : 0, "protocol" : "icmp", "from" : openstack_networking_secgroup_v2.workers, "to" : openstack_networking_secgroup_v2.workers },
      # kubelet
      { "port" : 10250, "protocol" : "tcp", "from" : openstack_networking_secgroup_v2.controlplanes, "to" : openstack_networking_secgroup_v2.controlplanes },
      { "port" : 10250, "protocol" : "tcp", "from" : openstack_networking_secgroup_v2.workers, "to" : openstack_networking_secgroup_v2.controlplanes },
      { "port" : 10250, "protocol" : "tcp", "from" : openstack_networking_secgroup_v2.controlplanes, "to" : openstack_networking_secgroup_v2.workers },
      { "port" : 10250, "protocol" : "tcp", "from" : openstack_networking_secgroup_v2.workers, "to" : openstack_networking_secgroup_v2.workers },
    ] :
    format("%s->%s-%s-%s", rule.from.name, rule.to.name, rule.protocol, rule.port) => rule
  }
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = each.value.protocol
  port_range_min    = each.value.port
  port_range_max    = each.value.port
  remote_group_id   = each.value.from.id
  security_group_id = each.value.to.id
}

/*
resource "openstack_networking_secgroup_rule_v2" "controlplanes4-2" {
  direction         = "ingress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.controlplanes.id
}

resource "openstack_networking_secgroup_rule_v2" "controlplanes6-2" {
  direction         = "ingress"
  ethertype         = "IPv6"
  security_group_id = openstack_networking_secgroup_v2.controlplanes.id
}

resource "openstack_networking_secgroup_rule_v2" "workers4-2" {
  direction         = "ingress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.workers.id
}

resource "openstack_networking_secgroup_rule_v2" "workers6-2" {
  direction         = "ingress"
  ethertype         = "IPv6"
  security_group_id = openstack_networking_secgroup_v2.workers.id
}
*/