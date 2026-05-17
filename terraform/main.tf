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

#import {
#  to = proxmox_virtual_environment_vm.docker_vms["prod-docker-01"]
#  id = "pve/100"
#}
#
#import {
#  to = proxmox_virtual_environment_vm.docker_vms["test-docker-01"]
#  id = "pve/200"
#}

resource "proxmox_virtual_environment_vm" "docker_vms" {
  for_each = {
    "vm-docker0" = { id = 100, cpu = 8, ram = 16384, ip = "10.1.10.100", data = 8 }
    "vm-docker1" = { id = 101, cpu = 6, ram = 16384, ip = "10.1.10.101", data = 8 }
    "vm-docker2" = { id = 102, cpu = 6, ram = 16384, ip = "10.1.10.102", data = 8 }
    "vm-docker3" = { id = 103, cpu = 6, ram = 16384, ip = "10.1.10.103", data = 8 }
    "vm-docker4" = { id = 104, cpu = 6, ram = 16384, ip = "10.1.10.104", data = 8 }
  }
  name      = each.key
  node_name = "pve"
  vm_id     = each.value.id

  clone {
    vm_id = 9000
  }

  cpu {
    cores = each.value.cpu
    type  = "host"
  }

  memory {
    dedicated = each.value.ram
  }

  network_device {
    bridge = "vmbr0"
  }

  vga {
    type = "serial0"
  }
  serial_device {}

  disk {
    datastore_id = "local-lvm"
    size         = 20
    interface    = "scsi0"
    file_format  = "raw"
  }

  disk {
    size = each.value.data
    interface = "scsi1"
    datastore_id = "local-lvm"
    file_format = "raw"
  }

  agent {
    enabled = true
  }

  initialization {
    datastore_id = "local-lvm"
    interface    = "ide2"


    dns {
      servers = [ each.key == "prod-docker-01" ? "127.0.0.1" : "1.1.1.1" ]
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
