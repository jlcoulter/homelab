# Homelab Terraform Infrastructure

This Terraform configuration provisions Docker host VMs on a Proxmox VE cluster. It creates Ubuntu Server cloud-init VMs with persistent storage, networking, and SSH access configured.

## Overview

- Production Docker hosts
- Test Docker hosts

Both VMs are configured with:
- Ubuntu Server 22.04 (Jammy) cloud image
- SSH key authentication
- Static IP addresses
- DNS configuration (prod uses local DNS, test uses prod)
- Serial console access

## Prerequisites

- Proxmox VE 7+ cluster
- API token with VM management permissions
- SSH key pair (`~/.ssh/id_ed25519.pub`)
- Terraform 1.0+
- Access to Proxmox API endpoint

## Setup

1. **Install Terraform** (if not installed):
   ```bash
   # Ubuntu/Debian
   sudo apt update && sudo apt install -y terraform
   ```

2. **Configure secrets**:
   - Edit `secret.tfvars` with your Proxmox API token and desired user password
   - API token format: `user@pam!token_name=token_value`

3. **Verify Proxmox access**:
   - Ensure Proxmox endpoint is reachable
   - Test API token: `curl -k https://10.1.10.10:8006/api2/json/access/ticket -H "Authorization: PVEAPIToken=root@pam!api_token=YOUR_TOKEN"`

## Running

### Initialize
```bash
tofu init
```

### Plan changes
```bash
tofu plan -var-file=secret.tfvars
```

### Apply changes
```bash
tofu apply -var-file=secret.tfvars
```

### Destroy VMs
```bash
tofu destroy -var-file=secret.tfvars
```

## Configuration

### Key Files

- `main.tf`: Main Terraform configuration
- `secret.tfvars`: Sensitive variables (API token, passwords)
- `terraform.tfstate`: Current state (auto-generated)
- `terraform.tfstate.backup`: State backup (auto-generated)

### Variables

- `api_token`: Proxmox API token (required)
- `user_password`: VM user password (required)

### VM Specifications

Defined in `main.tf` resource `proxmox_virtual_environment_vm.docker_vms`:

```hcl
"prod-docker-01" = { id = 100, cpu = 4, ram = 8192, ip = "10.1.10.100", data = 8 }
"test-docker-01" = { id = 200, cpu = 2, ram = 8192, ip = "10.1.10.200", data = 4}
```

- `id`: VM ID in Proxmox
- `cpu`: CPU cores
- `ram`: RAM in MB
- `ip`: Static IP address
- `data`: Data disk size in GB

### Networking

- Bridge: `vmbr0`
- Gateway: `10.1.10.1`
- DNS: Prod uses `127.0.0.1` (AdGuard), Test uses `10.1.10.100` (Prod)

## Extending

### Adding a new VM

1. Add entry to the `for_each` map in `main.tf`:
   ```hcl
   "new-vm" = { id = 300, cpu = 2, ram = 4096, ip = "10.1.10.150", data = 4 }
   ```

2. Update Ansible inventory and app mappings accordingly

### Modifying VM specs

Edit the values in the `for_each` map. Common changes:
- Increase `ram` for memory-intensive apps
- Add `cpu` cores for CPU-bound workloads
- Adjust `data` disk size for storage needs

### Changing OS image

Update `file_id` in the OS disk resource to point to a different cloud-init image.

## Troubleshooting

### Common Issues

- **API connection fails**: Check endpoint URL, API token, and network connectivity
- **SSH key not found**: Ensure `~/.ssh/id_ed25519.pub` exists
- **VM creation fails**: Verify datastore space and VM ID availability
- **Cloud-init fails**: Check user credentials and network config

### Debugging

```bash
# Verbose output
tofu apply -var-file=secret.tfvars -verbose

# Check state
tofu show

# Refresh state
tofu refresh -var-file=secret.tfvars
```

### Proxmox Logs

Check Proxmox web UI or logs for VM creation errors:
```bash
# On Proxmox host
journalctl -u pveproxy
```

### State Management

- Never edit `terraform.tfstate` manually
- Use `terraform state` commands for modifications
- Backup state files before major changes

## Integration with Ansible

After Terraform provisions VMs:

1. VMs will be accessible via SSH with your key
2. Update Ansible `inventory.ini` with VM IPs
3. Run Ansible playbook to install Docker and apps

## Best Practices

- Keep `secret.tfvars` out of version control
- Use different API tokens for different environments
- Test with `terraform plan` before applying
- Document any customizations
- Regularly backup Terraform state