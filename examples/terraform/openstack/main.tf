module "openstack" {
  source = "./openstack"

  cluster_name             = var.cluster_name
  talos_version            = var.talos_version
  ssh_authorized_keys      = var.ssh_authorized_keys
  lb_provider              = var.lb_provider
  dns_nameservers4         = var.dns_nameservers4
  subnet_controlplane_cidr = var.subnet_controlplane_cidr
  subnet_agents_cidr       = var.subnet_agents_cidr
  subnet_lb_cidr           = var.subnet_lb_cidr
  floating_pool            = var.floating_pool
  rules_talos_cidr         = var.rules_talos_cidr
  rules_k8s_cidr           = var.rules_k8s_cidr

  controlplanes = var.controlplanes
  workers       = var.workers

  k8s_cilium  = var.k8s_cilium
  k8s_ccm     = var.k8s_ccm
  k8s_csi     = var.k8s_csi
  k8s_metrics = var.k8s_metrics
}

module "k8s" {
  source       = "./k8s"
  cluster_name = var.cluster_name

  kubernetes_client_configuration = module.openstack.kubernetes_client_configuration

  lb_id                  = module.openstack.lb_id
  lb_network_id          = module.openstack.lb_network_id
  lb_subnet_id           = module.openstack.lb_subnet_id
  lb_floating_network_id = module.openstack.lb_floating_network_id

  k8s_cilium = var.k8s_cilium
  k8s_ccm    = var.k8s_ccm
  k8s_csi    = var.k8s_csi
  k8s_nginx  = var.k8s_nginx
}
