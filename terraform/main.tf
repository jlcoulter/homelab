terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.106.0"
    }
  }
}

data "local_file" "ssh_public_key" {
  filename = pathexpand("~/.ssh/id_ed25519.pub")
}

variable "api_token" {
  type      = string
  sensitive = true
}

variable "user_password" {
  type = string
  sensitive = true
}

provider "proxmox" {
  endpoint  = "https://10.1.10.10:8006/"
  api_token = var.api_token
  insecure  = true

  ssh {
    agent = true
    username = "root"
  }
}

resource "proxmox_virtual_environment_vm" "docker_vms" {
  for_each = {
    "prod-docker-01" = { id = 100, cpu = 4, ram = 8192, ip = "10.1.10.100", data = 8 }
    "test-docker-01" = { id = 200, cpu = 2, ram = 8192, ip = "10.1.10.200", data = 4}
  }
  name      = each.key
  node_name = "pve"
  vm_id     = each.value.id

  cpu {
    cores = each.value.cpu
    type  = "host"
  }

  memory {
    dedicated = each.value.ram
  }

  network_device {
    bridge = "vmbr0"
    # vlan_id = 10
    # model = "virtio"
  }

  vga {
    type = "serial0"
  }
  serial_device {}

  disk {
    datastore_id = "local-zfs"
    file_id = "local:iso/jammy-server-cloudimg-amd64.img"
    size         = 20
    interface    = "scsi0"
    file_format  = "raw"
  }

  disk {
    size = each.value.data
    interface = "scsi1"
    datastore_id = "local-zfs"
    file_format = "raw"
  }


  initialization {
    datastore_id = "local-zfs"

    dns {
      servers = [ each.key == "prod-docker-01" ? "127.0.0.1" : "10.1.10.100" ]
    }

    user_account {
      username = "jc"
      password = var.user_password
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }
        ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = "10.1.10.1"
      }
    }
  }


      lifecycle {
    prevent_destroy = false
  }
}

# resource "proxmox_download_file" "ubuntu_cloud_image" {
#   overwrite = true
#   content_type = "iso"
#   datastore_id = "local"
#   node_name    = "pve"
#   url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
#   # need to rename the file to *.qcow2 to indicate the actual file format for import
#   file_name = "jammy-server-cloudimg-amd64.img"
# }
