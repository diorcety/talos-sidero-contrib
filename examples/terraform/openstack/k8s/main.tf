locals {
  identity_service      = [for entry in data.openstack_identity_auth_scope_v3.scope.service_catalog : entry if entry.type == "identity"][0]
  csi_identity_endpoint = [for endpoint in local.identity_service.endpoints : endpoint if(endpoint.interface == "public" && endpoint.region == openstack_identity_application_credential_v3.talos_csi.region)][0]
  ccm_identity_endpoint = [for endpoint in local.identity_service.endpoints : endpoint if(endpoint.interface == "public" && endpoint.region == openstack_identity_application_credential_v3.talos_ccm.region)][0]
}

resource "helm_release" "cilium" {
  count      = var.k8s_cilium ? 1 : 0
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = "v1.14.4"
  namespace  = "kube-system"

  values = [file("${path.module}/values/cilium.yaml")]
}

resource "helm_release" "ccm" {
  count     = var.k8s_ccm ? 1 : 0
  name      = "openstack-ccm"
  chart     = "${path.module}/../dependencies/cloud-provider-openstack/charts/openstack-cloud-controller-manager"
  version   = "v2.28.3"
  namespace = "kube-system"

  values = [templatefile("${path.module}/values/ccm.yaml", {
    auth_url   = local.ccm_identity_endpoint.url
    region     = local.ccm_identity_endpoint.region
    project_id = openstack_identity_application_credential_v3.talos_ccm.project_id
    app_id     = openstack_identity_application_credential_v3.talos_ccm.id
    app_secret = openstack_identity_application_credential_v3.talos_ccm.secret

    lb_provider            = var.lb_provider
    lb_network_id          = var.lb_network_id
    lb_subnet_id           = var.lb_subnet_id
    lb_floating_network_id = var.lb_floating_network_id
  })]
}

resource "helm_release" "csi" {
  count     = var.k8s_csi ? 1 : 0
  name      = "cinder-csi-plugin"
  chart     = "${path.module}/../dependencies/cloud-provider-openstack/charts/cinder-csi-plugin"
  version   = "v2.28.1"
  namespace = "kube-system"

  values = [templatefile("${path.module}/values/csi.yaml", {
    auth_url   = local.csi_identity_endpoint.url
    region     = local.csi_identity_endpoint.region
    project_id = openstack_identity_application_credential_v3.talos_csi.project_id
    app_id     = openstack_identity_application_credential_v3.talos_csi.id
    app_secret = openstack_identity_application_credential_v3.talos_csi.secret
  })]
}

resource "helm_release" "nginx-ingress" {
  count            = var.k8s_nginx && var.k8s_ccm ? 1 : 0
  name             = "nginx-ingress"
  chart            = "oci://ghcr.io/nginxinc/charts/nginx-ingress"
  version          = "1.0.2"
  namespace        = "nginx-ingress"
  create_namespace = true

  values = [templatefile("${path.module}/values/nginx-ingress.yaml", {
    lb_id = var.lb_id
  })]

  depends_on = [helm_release.ccm]
}

