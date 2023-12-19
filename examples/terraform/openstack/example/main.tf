module "talos_openstack" {
  source = "./../"

  floating_pool = "ext-floating1"

  ssh_authorized_keys = ["./id_rsa.pub"]

  rules_k8s_cidr   = "0.0.0.0/0"
  rules_talos_cidr = "0.0.0.0/0"

  controlplanes = [{
    name               = "control-plane"
    flavor_name        = "a4-ram8-disk20-perf2"
    nodes_count        = 1
    region             = "dc3-a"
    availability_zones = ["dc3-a-10", "dc3-a-09", "dc3-a-04"]
  }]

  workers = [{
    name               = "worker"
    flavor_name        = "a4-ram8-disk20-perf2"
    nodes_count        = 1
    region             = "dc3-a"
    availability_zones = ["dc3-a-04", "dc3-a-09", "dc3-a-10"]
  }]
}
