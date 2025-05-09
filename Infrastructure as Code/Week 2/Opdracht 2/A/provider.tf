terraform {

    required_providers {
      vsphere = {
        source = "vsphere"
        version = "~> 2.11.1"
      }
    }
}

provider "vsphere" {
  user = var.vsphere_user
  password = var.vsphere_password
  vsphere_server = var.vsphere_server
  allow_unverified_ssl = true
}

variable "vsphere_user" {
    type = string
}

variable "vsphere_password" {
    type = string
}

variable "vsphere_server" {
    type = string
}

variable "ssh_username" {
    type = string
}

variable "ssh_key" {
    type = string
}


