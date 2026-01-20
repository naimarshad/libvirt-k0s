output "node_ips" {
  value = { for k, v in var.nodes : k => v.ip }
}

output "node_names" {
  value = { for k, v in var.nodes : k => v.name }
}

output "network_name" {
  value = libvirt_network.k0s.name
}
