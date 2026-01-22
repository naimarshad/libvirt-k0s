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
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}

# Configure Helm to use the generated kubeconfig
provider "helm" {
  kubernetes = {
    config_path = fileexists("${path.module}/kubeconfig") ? "${abspath(path.module)}/kubeconfig" : "${abspath(path.module)}/kubeconfig.placeholder"
  }
}

# Configure Kubernetes to use the generated kubeconfig
provider "kubernetes" {
  config_path = fileexists("${path.module}/kubeconfig") ? "${abspath(path.module)}/kubeconfig" : "${abspath(path.module)}/kubeconfig.placeholder"
}