terraform {
  required_version = ">= 1.4.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">= 0.7.6, < 0.9.0"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}
