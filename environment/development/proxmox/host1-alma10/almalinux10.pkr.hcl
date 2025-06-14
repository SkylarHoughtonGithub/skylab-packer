packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_url" {
  type    = string
  default = "https://host1.skylarhoughtongithub.local:8006/api2/json"
}

variable "proxmox_username" {
  type    = string
  default = "terraform-prov@pve!mytoken"
}

variable "proxmox_token" {
  type    = string
  default = ""
}

variable "proxmox_node" {
  type    = string
  default = "host1"
}

variable "vm_id" {
  type    = string
  default = "999"
}

variable "template_name" {
  type    = string
  default = "almalinux-9-template"
}

variable "iso_file" {
  type    = string
  default = "local:iso/AlmaLinux-10.0-x86_64-dvd.iso"
}

source "proxmox-iso" "almalinux9" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  token                    = var.proxmox_token
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  vm_id                = var.vm_id
  vm_name              = var.template_name
  template_description = "AlmaLinux 9 template built with Packer"

  boot_iso {
    iso_file         = var.iso_file
    iso_storage_pool = "local-zfs"
  }

  qemu_agent      = true
  scsi_controller = "virtio-scsi-pci"

  disks {
    type         = "scsi"
    disk_size    = "20G"
    storage_pool = "local-zfs"
  }

  cores  = "2"
  memory = "2048"

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }

  cloud_init              = true
  cloud_init_storage_pool = "local-zfs"

  boot_command = [
    "<tab><end> ks=http://{{.HTTPIP}}:{{.HTTPPort}}/ks.cfg<ctrl-x>"
  ]

  boot      = "c"
  boot_wait = "10s"

  http_directory = "http"
  http_port_min  = 8080
  http_port_max  = 8090

  ssh_username             = "root"
  ssh_password             = "packer"
  ssh_timeout              = "20m"
  ssh_handshake_attempts   = 100
}

build {
  sources = ["source.proxmox-iso.almalinux9"]

  provisioner "shell" {
    inline = [
      "dnf update -y",
      "dnf install -y qemu-guest-agent cloud-init cloud-utils-growpart",
      "systemctl enable qemu-guest-agent",
      "systemctl enable cloud-init",
      "systemctl enable cloud-init-local",
      "systemctl enable cloud-config",
      "systemctl enable cloud-final"
    ]
  }

  provisioner "shell" {
    inline = [
      "dnf install -y curl wget vim htop git epel-release",
      "dnf clean all"
    ]
  }

  provisioner "shell" {
    inline = [
      "cloud-init clean",
      "rm -rf /var/lib/cloud/instances/*",
      "rm -rf /var/log/cloud-init*",
      "truncate -s 0 /etc/machine-id",
      "rm -f /var/lib/dbus/machine-id",
      "ln -s /etc/machine-id /var/lib/dbus/machine-id",
      "rm -f /root/.bash_history",
      "history -c"
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}