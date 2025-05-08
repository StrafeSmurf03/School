data "azurerm_resource_group" "rg" {
  name = "S1204419"
}

output "id" {
  value = data.azurerm_resource_group.rg.id
}

resource "azurerm_virtual_network" "vnet" {
  name                = "ubuntu-network"
  address_space       = ["10.0.0.0/16"]
  location            = "West Europe"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "ubuntu-vm-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "ubuntu-vm"
  resource_group_name   = data.azurerm_resource_group.rg.name
  location              = data.azurerm_resource_group.rg.location
  size                  = "Standard_B2ats_v2"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = "adminuser"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCp5BcorD4QOeGSA1CMn7QeLIUKtd1X32gZFF2/OJOGX3eI/I46A3pb3l4CovL3sfMDJq0U2amg+M6L9kzM6EV4L3oGxgaCy1tK9wcZNMQckmKrCniKHVdpWvfVtPjLIwHnffrJXUUuIBCHz0eDl08XmbQkOwziWwhxXH3/+/ezlkHkgWNrtRwNXpDygEDaVRxO5GxkBavOx3zn1vNnu6HEysFsen5Akjy8hUzZnTO+lGW4tL8u7UdkYGDjjnDC1BvMsBFQuwgCMDVLChNCX0HarNzEqmnbpvWym+ffI3zSxiGo4jM7aAMwc4R9s2E4Eh+tK0ArtsHpPLhdIdB3NB23 rsa-key-20250508"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"  # Ubuntu 22.04 LTS
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}