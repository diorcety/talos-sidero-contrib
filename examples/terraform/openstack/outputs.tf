
output "talosconfig" {
  value     = module.openstack.talosconfig
  sensitive = true
}

output "kubeconfig" {
  value     = module.openstack.kubeconfig
  sensitive = true
}
