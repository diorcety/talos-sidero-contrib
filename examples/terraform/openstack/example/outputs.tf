
output "talosconfig" {
  value     = module.talos_openstack.talosconfig
  sensitive = true
}

output "kubeconfig" {
  value     = module.talos_openstack.kubeconfig
  sensitive = true
}
