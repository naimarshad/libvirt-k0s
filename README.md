# Libvirt/KVM K0s Cluster Play

This play builds 1 control plane + 3 worker VMs on libvirt/KVM, then provisions k0s with Calico as the CNI and Traefik as the ingress controller.

## Prereqs

- Libvirt + KVM installed and running (qemu:///system)
- `terraform` or `tofu` installed
- `k0sctl`, `kubectl`, and `helm` installed on the host
- A cloud image on disk (for example `noble-server-cloudimg-amd64.img`) should be available at

  - /var/lib/libvirt/images/noble-server-cloudimg-amd64.img

## Provision VMs with Terraform/OpenTofu

1. Copy the example variables file and edit values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Update `terraform.tfvars`:

- `base_image` path for your OS image
- `ssh_authorized_keys` with your public key(s)
- `nodes` IPs/MACs if needed for your network

3. Apply:

```bash
cd libvirt-k0s
terraform init
terraform apply
```

This module pins `dmacvicar/libvirt` to `< 0.9.0` to keep the classic schema

## Prepare k0sctl config

The libvirt-ready config is at `k0sctl-libvirt.yaml`.

Make sure these match your VM IPs and SSH key:

- `hosts[*].ssh.address`
- `hosts[*].ssh.keyPath`
- `k0s.config.spec.api.address`

Calico manifests are already wired into the controller node via `files` and `hooks`.

## Generate the kubeconfig and use it

```
k0sctl kubeconfig --config k0sctl-libvirt.yaml > kubeconfig
export ./kubeconfig
```

## Verify the cluster state

```
kubectl get nodes -owide
```

## Install Traefik (no built-in ingress)

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
kubectl create ns traefik 2>/dev/null || true
helm upgrade --install traefik traefik/traefik \
  --namespace traefik --create-namespace \
  --values traefik/values.yaml
```

 Traefik runs as a DaemonSet on host network ports 80/443 (see `traefik/values.yaml`).

## Install cert-manager + Cloudflare DNS01

### First Make sure change the email to your registered email to use with acme

```
sed -i 's/acme_registration_email/<YOUR_EMAIL>/' cert-manager/cluster-issuer.yaml

```

### Add your cloudflare api token which have appropriate permissions.

```
sed -i 's/CHANGEME/<YOUR_TOKEN>/' cert-manager/cloudflare-api-token-values.example.yaml
cp cert-manager/cloudflare-api-token-values.example.yaml cert-manager/cloudflare-api-token-values.local.yaml
```

### Finally Install Cert Manager

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --values cert-manager/values.yaml \
  --values cert-manager/cloudflare-api-token-values.local.yaml
```

### Apply cluster-issuer manifest

```
kubectl apply -f cert-manager/cluster-issuer.yaml
```

## Validate

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl get svc -n traefik
```

## Notes

- Static IPs are configured via cloud-init `network_config`, using `nodes[*].ip` and `nodes[*].mac`.
- If you want a different network CIDR, update `network_cidr` in `terraform.tfvars`.
- VM user defaults to `ubuntu`. Update `ssh_username` in `terraform.tfvars` if needed.
