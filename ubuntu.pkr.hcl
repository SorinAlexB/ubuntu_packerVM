packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.0.5"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

variable "vm_name" {
  type    = string
  default = "ubuntu-22.04_opencrs"
}

variable "cpu_cores" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 4096
}

variable "disk_size" {
  type    = number
  default = 40000
}

source "virtualbox-iso" "ubuntu" {
  guest_os_type    = "Ubuntu_64"
  iso_url      = "https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso"
  iso_checksum = "9bc6028870aef3f74f4e16b900008179e78b130e6b0b9a140635434a46aa98b0"
  ssh_username     = "opencrs"
  ssh_password     = "opencrs"
  ssh_timeout      = "60m"
  ssh_port         = 22
  ssh_wait_timeout = "60m"
  ssh_handshake_attempts = "100"
  
  shutdown_command = "echo 'ubuntu' | sudo -S shutdown -P now"

  cpus      = var.cpu_cores
  memory    = var.memory
  disk_size = var.disk_size

  boot_wait = "5s"
  http_directory = "http"
  boot_command = [
    "<wait>c<wait>",
    "set gfxpayload=keep<enter><wait>",
    "linux /casper/vmlinuz<wait>",
    " autoinstall<wait>",
    " ds=nocloud-net\\;s=http://{{.HTTPIP}}:{{.HTTPPort}}/<wait>",
    " quiet splash<wait>",
    " ---<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  vm_name              = var.vm_name
  guest_additions_mode = "disable"
  headless            = false

  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--rtcuseutc", "on"],
    ["modifyvm", "{{.Name}}", "--graphicscontroller", "vmsvga"],
    ["modifyvm", "{{.Name}}", "--accelerate3d", "off"],
  ]
}

build {
  sources = ["source.virtualbox-iso.ubuntu"]
}