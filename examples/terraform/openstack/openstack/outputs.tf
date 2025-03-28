
output "talosconfig" {
  value     = data.talos_client_configuration.talosconfig.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  sensitive = true
}

output "kubernetes_client_configuration" {
  value = talos_cluster_kubeconfig.kubeconfig.kubernetes_client_configuration
}

output "lb_id" {
  value = openstack_lb_loadbalancer_v2.lb.id
}

output "lb_network_id" {
  value = openstack_networking_network_v2.net.id
}

output "lb_subnet_id" {
  value = openstack_networking_subnet_v2.lb.id
}

output "lb_floating_network_id" {
  value = data.openstack_networking_network_v2.floating_net.id
}
