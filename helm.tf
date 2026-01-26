# Install Cert-Manager
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  values = [
    file("${path.module}/cert-manager-config/values.yaml")
  ]

  depends_on = [null_resource.k0sctl_apply]
}

# Create the Cloudflare API Token Secret
resource "kubernetes_secret_v1" "cloudflare_api_token" {
  metadata {
    name      = "cloudflare-api-token"
    namespace = "cert-manager"
  }

  type = "Opaque"

  data = {
    api-token = var.cloudflare_api_token
  }

  depends_on = [helm_release.cert_manager]
}


# Create the ClusterIssuer using kubectl to avoid CRD plan-time validation issues
resource "null_resource" "cluster_issuer" {
  triggers = {
    manifest_hash = sha256(templatefile("${path.module}/cert-manager-config/cluster-issuer.yaml", {
      acme_email = var.acme_email
    }))
  }

  provisioner "local-exec" {
    command = <<EOT
      export KUBECONFIG=${abspath(path.module)}/kubeconfig
      # Wait for CRD to be established
      count=0
      until kubectl get crd clusterissuers.cert-manager.io || [ $count -eq 20 ]; do
        sleep 5
        count=$((count + 1))
      done
      echo '${templatefile("${path.module}/cert-manager-config/cluster-issuer.yaml", { acme_email = var.acme_email })}' | kubectl apply -f -
    EOT
  }

  depends_on = [
    helm_release.cert_manager,
    kubernetes_secret_v1.cloudflare_api_token
  ]
}

resource "helm_release" "lti-rustfs" {
  name             = "rustfs"
  repository       = "https://charts.rustfs.com"
  chart            = "rustfs"
  namespace        = "rustfs"
  create_namespace = true

  values = [
    file("${path.module}/lti-rustfs/values.yaml")
  ]

  depends_on = [
    helm_release.cert_manager,
    kubernetes_secret_v1.cloudflare_api_token,
    null_resource.cluster_issuer
  ]
}
