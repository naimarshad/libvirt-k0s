terraform {
  required_version = ">= 1.4.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">= 0.7.6, < 0.9.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}

# Read the kubeconfig file after it's generated
data "local_file" "kubeconfig" {
  filename   = "${path.module}/kubeconfig"
  depends_on = [null_resource.k0sctl_apply]
}

locals {
  kubeconfig = yamldecode(data.local_file.kubeconfig.content)
}

# Configure Helm to use the generated kubeconfig
provider "helm" {
  kubernetes = {
    host                   = local.kubeconfig.clusters[0].cluster.server
    client_certificate     = base64decode(local.kubeconfig.users[0].user.client-certificate-data)
    client_key             = base64decode(local.kubeconfig.users[0].user.client-key-data)
    cluster_ca_certificate = base64decode(local.kubeconfig.clusters[0].cluster.certificate-authority-data)
  }
}

# Configure Kubernetes to use the generated kubeconfig
provider "kubernetes" {
  host                   = local.kubeconfig.clusters[0].cluster.server
  client_certificate     = base64decode(local.kubeconfig.users[0].user.client-certificate-data)
  client_key             = base64decode(local.kubeconfig.users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(local.kubeconfig.clusters[0].cluster.certificate-authority-data)
}