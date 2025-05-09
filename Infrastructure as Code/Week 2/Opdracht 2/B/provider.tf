terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.28.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  subscription_id = "c064671c-8f74-4fec-b088-b53c568245eb"
}

provider "local" {
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "S1204419"
}

variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "ubuntu"
}

variable "location" {
  description = "The Azure location where resources will be created"
  type        = string
  default     = "West Europe"
}

variable "vm_size" {
  description = "The size of the VM"
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 2
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "adminuser"
}

variable "iac_username" {
  description = "The IAC user to be created"
  type        = string
  default     = "iac"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIGDaxKQRnuJW2bfIvumIYAKhZxHLCHpRJ9e4bdq7r4O"
}

variable "image_publisher" {
  description = "Publisher of the VM image"
  type        = string
  default     = "Canonical"
}

variable "image_offer" {
  description = "Offer of the VM image"
  type        = string
  default     = "ubuntu-24_04-lts"
}

variable "image_sku" {
  description = "SKU of the VM image"
  type        = string
  default     = "server"
}

variable "image_version" {
  description = "Version of the VM image"
  type        = string
  default     = "latest"
}