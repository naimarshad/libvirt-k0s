variable "libvirt_uri" {
  type        = string
  description = "Libvirt connection URI."
  default     = "qemu:///system"
}

variable "base_image" {
  type        = string
  description = "Path to the base cloud image (qcow2)."
}

variable "pool_name" {
  type        = string
  description = "Libvirt storage pool name."
  default     = "default"
}

variable "network_name" {
  type        = string
  description = "Libvirt network name."
  default     = "k0s-net"
}

variable "network_cidr" {
  type        = string
  description = "CIDR for the libvirt NAT network."
  default     = "192.168.150.0/24"
}

variable "nodes" {
  type = map(object({
    name   = string
    role   = string
    ip     = string
    mac    = string
    vcpu   = number
    memory = number
  }))
  description = "Map of cluster nodes with fixed IP/MAC."
}

variable "os_disk_size" {
  type        = number
  description = "OS disk size in bytes."
  default     = 21474836480
}

variable "ssh_username" {
  type        = string
  description = "Linux user to create on the VM."
  default     = "ubuntu"
}

variable "ssh_authorized_keys" {
  type        = list(string)
  description = "SSH public keys for the VM user."
}

variable "timezone" {
  type        = string
  description = "Timezone for the VM."
  default     = "UTC"
}

variable "dns_servers" {
  type        = list(string)
  description = "DNS servers for static IP configuration."
  default     = ["1.1.1.1", "8.8.8.8"]
}
