data "openstack_images_image_v2" "image" {
  name        = var.image_name
  most_recent = true
}

resource "openstack_networking_port_v2" "port" {
  count = var.nodes_count

  network_id         = var.network_id
  security_group_ids = [var.secgroup_id]
  admin_state_up     = true

  fixed_ip {
    subnet_id = var.subnet_id
  }
}


resource "openstack_compute_instance_v2" "instance" {
  count = var.nodes_count

  name                    = "${var.name}-${count.index}"
  availability_zone_hints = length(var.availability_zones) > 0 ? var.availability_zones[count.index % length(var.availability_zones)] : null
  region                  = var.region
  flavor_name             = var.flavor_name

  user_data = var.user_data

  image_id = data.openstack_images_image_v2.image.id
  key_pair = var.keypair_name

  network {
    port = openstack_networking_port_v2.port[count.index].id
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}
