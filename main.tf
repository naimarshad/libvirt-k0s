resource "libvirt_network" "k0s" {
  name      = var.network_name
  mode      = "nat"
  domain    = "k0s.local"
  addresses = [var.network_cidr]

  dns {
    enabled = true
  }
  dhcp {
    enabled = false
  }
}

resource "libvirt_volume" "os" {
  for_each       = var.nodes
  name           = "${each.value.name}-os.qcow2"
  pool           = var.pool_name
  base_volume_id = var.base_image
  size           = var.os_disk_size
  format         = "qcow2"
}

resource "libvirt_cloudinit_disk" "node" {
  for_each  = var.nodes
  name      = "${each.value.name}-cloudinit"
  pool      = var.pool_name
  user_data = templatefile("${path.module}/cloudinit.tmpl", {
    hostname            = each.value.name
    ssh_username        = var.ssh_username
    ssh_authorized_keys = var.ssh_authorized_keys
    timezone            = var.timezone
  })
  network_config = templatefile("${path.module}/network_config.tmpl", {
    ip_address  = each.value.ip
    mac_address = each.value.mac
    gateway     = cidrhost(var.network_cidr, 1)
    cidr_prefix = tonumber(split("/", var.network_cidr)[1])
    dns_servers = var.dns_servers
  })
}

resource "libvirt_domain" "node" {
  for_each = var.nodes
  name     = each.value.name
  memory   = each.value.memory
  vcpu     = each.value.vcpu

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.os[each.key].id
  }

  network_interface {
    network_id    = libvirt_network.k0s.id
    hostname      = each.value.name
    mac           = each.value.mac
  }

  cloudinit = libvirt_cloudinit_disk.node[each.key].id
}

resource "time_sleep" "wait_for_vms" {
  depends_on = [libvirt_domain.node]
  create_duration = "180s"
}

resource "null_resource" "k0sctl_apply" {
  depends_on = [libvirt_domain.node]

  triggers = {
    vm_ids = join(",", [for d in libvirt_domain.node : d.id])
  }

  provisioner "local-exec" {
    command     = "k0sctl apply --config ${abspath(path.module)}/k0sctl-libvirt.yaml && k0sctl kubeconfig --config ${abspath(path.module)}/k0sctl-libvirt.yaml > ${abspath(path.module)}/kubeconfig"
    working_dir = abspath(path.module)
  }
}
