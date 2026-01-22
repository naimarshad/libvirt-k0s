# Libvirt/KVM K0s Cluster Play

This play builds 1 control plane + 3 worker VMs on libvirt/KVM, then provisions k0s with Calico as the CNI and automatically installs Traefik and cert-manager via OpenTofu/Terraform in a single phase.

## Prereqs

- Libvirt + KVM installed and running (qemu:///system)
- `tofu` (OpenTofu) or `terraform` installed
- `k0sctl` installed on the host
- A cloud image on disk (for example `noble-server-cloudimg-amd64.img`) should be available at:
  - `/var/lib/libvirt/images/noble-server-cloudimg-amd64.img`

## Provisioning Workflow

The deployment is fully automated in a single apply. OpenTofu creates the VMs, runs `k0sctl`, generates the kubeconfig, and then installs Traefik and cert-manager.

1. Copy the example variables file and edit values:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
2. Update `terraform.tfvars`:

   - Set `base_image` path.
   - Add your `ssh_authorized_keys`.
   - Set `cloudflare_api_token` and `acme_email`.
3. Initialize and Apply:

   ```bash
   tofu init
   tofu apply
   ```

### How it works (one-phase apply)

1. Infrastructure: creates VMs and networking.
2. Cluster: runs `k0sctl` and writes `kubeconfig`.
3. Providers: Kubernetes/Helm providers load the generated kubeconfig.
4. Add-ons: installs Traefik, cert-manager, and the ClusterIssuer.

## Repository Structure

- `traefik-values/`: Contains the values.yaml for the Traefik Helm chart.
- `cert-manager-config/`: Contains the values.yaml and the ClusterIssuer manifest.
- `kubeconfig.placeholder`: A dummy config used by providers during the initial plan before the real cluster exists.

## Manual Cluster Management (Optional)

If you need to manually interact with the cluster:

```bash
# Export the generated kubeconfig
export KUBECONFIG=./kubeconfig

# Check node status
kubectl get nodes -o wide

# Check pods
kubectl get pods -A
```

## Notes

- **Persistence**: The `kubeconfig.placeholder` ensures `tofu plan` works on fresh clones.
- **Provider Switching**: The Kubernetes/Helm providers read the generated kubeconfig once it exists.
- **Dependencies**: The ClusterIssuer is applied via a `null_resource` using `kubectl` to ensure it waits for the cert-manager CRDs to be fully ready.
- **Network**: Static IPs are configured via cloud-init. Default CIDR is `192.168.150.0/24`.
