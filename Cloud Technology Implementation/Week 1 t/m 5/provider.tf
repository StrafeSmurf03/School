terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.30.0"
    }
    local = {
    source  = "hashicorp/local"
    version = "~> 2.5.3"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  subscription_id = "c064671c-8f74-4fec-b088-b53c568245eb"
}

variable "ssh_user" {
  description = "ssh username"
  type        = string
}

variable "ssh_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "ssh_key_path" {
  description = "SSH private key for Ansible script"
  type        = string
}