variable "vm_name" {
  type    = string
  default = "opencrs"
}

variable "guest_os_type" {
  type    = string
  default = "Ubuntu_64"
}

variable "iso_url" {
  type    = string
  default = "https://releases.ubuntu.com/22.04.1/ubuntu-22.04.1-live-server-amd64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:10f19c5b2b8d6db711582e0e27f5116296c34fe4b313ba45f9b201a5007056cb"
}

variable "iso_name" {
  type    = string
  default = "ubuntu-22.04.1-live-server-amd64.iso"
}

variable "cpus" {
  type    = number
  default = 1
}

variable "memsize" {
  type    = number
  default = 2048
}

variable "disk_size" {
  type    = number
  default = 20000
}

variable "disk_format" {
  type    = string
  default = "ova"
}

variable "username" {
  type    = string
  default = "opencrs_ubuntu"
}

variable "password" {
  type    = string
  default = "opencrs"
}

variable "headless" {
  type    = bool
  default = false
}

variable "img_name" {
  type    = string
  default = "opencrs"
}

variable "guest_additions_mode" {
  type    = string
  default = "disable"
}

variable "output_directory" {
  type    = string
  default = "output"
}

variable "checksum_directory" {
  type    = string
  default = "checksums"
}


packer {
  required_plugins {
    virtualbox = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

source "virtualbox-iso" "ubuntu-22-04" {
  guest_os_type = var.guest_os_type
  iso_url       = var.iso_url
  iso_checksum  = var.iso_checksum
  ssh_username  = var.username
  ssh_password  = var.password
  ssh_port = 2222
  ssh_host = "127.0.0.1"
  ssh_timeout   = "60m"
   http_content = {
     "/user-data" = templatefile("scripts/autoinst/ubuntu-22-04-autoinstall.yaml", {
       user = {
         username = var.username
         password = bcrypt(var.password)
       }
       hostname = var.vm_name
     }),
     "/meta-data" = ""
   }
  shutdown_command     = "rm -rf ~/.ansible && echo '${var.password}' | sudo -S poweroff"
  disk_size            = var.disk_size
  vm_name              = "${var.img_name}"
  format               = var.disk_format
  cpus                 = var.cpus
  memory               = var.memsize
  headless             = var.headless
  guest_additions_mode = var.guest_additions_mode
  virtualbox_version_file = ".vbox_version"
  output_directory     = var.output_directory
  vboxmanage = [
    ["modifyvm", "{{ .Name }}", "--audio", "pulse"],
    ["modifyvm", "{{ .Name }}", "--audiocontroller", "hda"],
    ["modifyvm", "{{ .Name }}", "--audioout", "on"],
    ["modifyvm", "{{ .Name }}", "--boot1", "dvd"],
    ["modifyvm", "{{ .Name }}", "--boot2", "disk"],
    ["modifyvm", "{{ .Name }}", "--pae", "off"],
    ["modifyvm", "{{ .Name }}", "--usb", "on"],
    ["modifyvm", "{{ .Name }}", "--vram", "16"],
    ["modifyvm", "{{ .Name }}", "--graphicscontroller", "vmsvga"],   
    ["modifyvm", "{{ .Name }}", "--vrde", "off"],
    ["modifyvm", "{{ .Name }}", "--nic1", "nat"],
    ["modifyvm", "{{ .Name }}", "--nictype1", "82540EM"],
    ["modifyvm", "{{ .Name }}", "--nic2", "hostonly"],    
    ["modifyvm", "{{ .Name }}", "--nictype2", "82540EM"],
    ["modifyvm", "{{ .Name }}", "--hostonlyadapter2", "vboxnet0"],
    ["modifyvm", "{{ .Name }}", "--memory", "${var.memsize}"],
    ["modifyvm", "{{ .Name }}", "--cpus", "${var.cpus}"],
    ["modifyvm", "{{ .Name }}", "--natpf1", "guestssh,tcp,,2222,,22"]
  ]

   boot_command = [
     "c<wait>",
     "linux /casper/vmlinuz --- autoinstall ds=\"nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}/\"",
     "<enter><wait>",
     "initrd /casper/initrd",
     "<enter><wait>",
     "boot",
     "<enter>"
   ]

  boot_wait = "5s"
}

build {
  sources = ["sources.virtualbox-iso.ubuntu-22-04"]

  provisioner "ansible" {
    playbook_file    = "scripts/ansible/master-lite.yml"
    user             = var.username
    use_proxy        = false
    extra_arguments  = [
      "--extra-vars", "ansible_password='${var.password}' ansible_become_pass='${var.password}'",
    ]
  }
}
