# Homelab Ansible Deployment

This Ansible project automates the deployment of Docker-based applications in a homelab environment. It supports both virtual machines (VMs) and Raspberry Pis (RPis), handling storage setup, Docker installation, and application deployment.

## Architecture

- **VMs**: Get persistent storage setup + Docker + apps
- **RPis**: Get Docker + apps (no storage role needed)
- **Roles**:
  - `storage`: Configures secondary disk for VMs
  - `docker`: Installs Docker engine and dependencies
  - `apps`: Deploys managed Docker Compose applications

## Prerequisites

- Ansible 2.9+ installed on control machine
- SSH access to all target hosts
- Ansible Vault password for secrets (if using encrypted vars)
- Target hosts: Ubuntu-based (tested on Ubuntu Server)

## Setup

1. **Clone the repository** (if not already done):
   ```bash
   git clone <repo-url>
   cd homelab/ansible
   ```

2. **Configure inventory**:
   - Edit `inventory.ini` to match your host IPs and groups
   - Ensure hosts are in `[vms]` or `[rpis]` groups as appropriate

3. **Configure secrets**:
   - export ANSIBLE_VAULT_PASSWORD_FILE=./.vault_pass
   - Edit `vars/secrets.yml` with any sensitive data
   - Encrypt with: `ansible-vault encrypt vars/secrets.yml`

4. **Verify connectivity**:
   ```bash
   ansible -i inventory.ini all -m ping
   ```

## Running

### Full deployment
```bash
ansible-playbook -i inventory.ini playbook.yml -K
```

### Target specific groups
```bash
# Only VMs
ansible-playbook -i inventory.ini playbook.yml -K --limit vms

# Only RPis
ansible-playbook -i inventory.ini playbook.yml -K --limit rpis
```

### Run specific roles/tags
```bash
# Only storage setup
ansible-playbook -i inventory.ini playbook.yml -K --tags storage

# Only Docker installation
ansible-playbook -i inventory.ini playbook.yml -K --tags docker

# Only app deployment
ansible-playbook -i inventory.ini playbook.yml -K --tags apps
```

## Extending

### Adding a new host

1. Add to `inventory.ini` under appropriate group (`[vms]` or `[rpis]`)
2. Update `group_vars/all.yml` `app_mapping` to assign apps to the new host

### Adding a new application

1. Create app directory: `../apps/newapp/`
2. Add `docker-compose.yml.j2` template
3. Add any config files (e.g., `settings.yaml`)
4. Update `roles/apps/defaults/main.yml`:
   - Add to `apps_managed_apps` list
   - Add to `apps_config_map` if needed
5. Update `group_vars/all.yml` `app_mapping` to assign to hosts

### Modifying app configs

- Edit templates in `../apps/<app>/`
- Update `apps_config_map` in `roles/apps/defaults/main.yml` for file mappings

### Adding new roles

1. Create `roles/newrole/` with standard structure
2. Add to playbook.yml plays as needed
3. Update defaults/vars as required

## Configuration

### Key Files

- `playbook.yml`: Main playbook with plays for VMs and RPis defining roles of each
- `inventory.ini`: Host inventory and groups
- `group_vars/all.yml`: Global variables (app mappings, Python interpreter)
- `roles/*/defaults/main.yml`: Role-specific defaults
- `vars/secrets.yml`: Encrypted sensitive variables
- `../apps/`: Application templates and configs

### Important Variables

- `app_mapping`: Dict mapping hosts to list of apps (in `group_vars/all.yml`)
- `apps_managed_apps`: List of all deployable apps (in `roles/apps/defaults/main.yml`)
- `apps_config_map`: Config file mappings per app (in `roles/apps/defaults/main.yml`)
- `docker_data_mount`: Mount point for persistent data (in `roles/storage/defaults/main.yml`)
- `secondary_disk`: Disk device for storage (in `roles/storage/defaults/main.yml`)

### Secrets

Store sensitive data in `vars/secrets.yml` and encrypt with Ansible Vault. Common secrets:
- API keys
- Database passwords
- Private registry credentials

## Troubleshooting

### Common Issues

- **SSH connection fails**: 
  - **Check SSH keys**: Ensure your public key is on target hosts
  - **Firewall**: Verify SSH port (22) is open
  - **Inventory IPs**: Confirm IPs in `inventory.ini` are correct
  
  **Adding a new VM to inventory**:
  1. Edit `inventory.ini`
  2. Add under `[vms]` or `[rpis]` group:
     ```
     newhost ansible_host=192.168.1.100
     ```
  3. Test connection: `ansible -i inventory.ini newhost -m ping`
  
  **Setting up SSH keys on all hosts**:
  1. Generate key on control machine (if not exists):
     ```bash
     ssh-keygen -t ed25519 -C "ansible-control"
     ```
  2. Copy to each target host:
     ```bash
     ssh-copy-id user@host-ip
     ```
     Or for all hosts:
     ```bash
     for host in $(ansible -i inventory.ini all --list-hosts | grep -v hosts); do
       ssh-copy-id $host
     done
     ```
  3. Verify: `ansible -i inventory.ini all -m ping`

- **Vault decryption fails**: Ensure correct vault password
- **Docker install fails**: Verify Ubuntu version compatibility
- **App deployment fails**: Check app templates and host assignments

### Debugging

```bash
# Verbose output
ansible-playbook -i inventory.ini playbook.yml -K -v

# Check syntax
ansible-playbook -i inventory.ini playbook.yml -K --syntax-check

# Dry run
ansible-playbook -i inventory.ini playbook.yml -K --check
```

### Logs

- Ansible output shows task results
- Check target host logs: `journalctl -u docker` for Docker issues
- App logs: `docker-compose logs` in `/opt/<app>/`

## Best Practices

- Always test with `--check` first
- Use tags to run partial deployments
- Keep secrets encrypted with Vault
- Version control all changes
- Document customizations in this README