data "openstack_identity_auth_scope_v3" "scope" {
  name = "auth_scope"
}

resource "openstack_identity_application_credential_v3" "talos_ccm" {
  name = "${var.cluster_name}-ccm-credentials"
}

resource "openstack_identity_application_credential_v3" "talos_csi" {
  name = "${var.cluster_name}-csi-credentials"
}
