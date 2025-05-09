data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

output "id" {
  value = data.azurerm_resource_group.rg.id
}

output "vm_public_ips" {
  value = [for ip in azurerm_public_ip.public_ip : ip.ip_address]
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-network2"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  count               = var.vm_count
  name                = "${var.prefix}-ip-${count.index}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "${var.prefix}-nic-${count.index}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.public_ip[count.index].id
    private_ip_address            = "10.0.2.1${count.index}"
  }
}

resource "azurerm_network_security_group" "NSG_SSH" {
  name                = "nsg-1-allowinbound-tcp"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow_Inbound_TCP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface_security_group_association" "add" {
  count 	= var.vm_count
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.NSG_SSH.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                 = var.vm_count
  name                  = "${var.prefix}-vm-${count.index}"
  resource_group_name   = data.azurerm_resource_group.rg.name
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  custom_data = base64encode(templatefile("${path.module}/cloudinit/cloud-init.tpl", {
    iac_username = var.iac_username
    ssh_key = var.ssh_public_key
  }))
}

# Save VM IP addresses to a local file
resource "local_file" "ip_addresses" {
  content  = join("\n", [for ip in azurerm_public_ip.public_ip : ip.ip_address])
  filename = "${path.module}/vm_ip_addresses.txt"
  depends_on = [azurerm_public_ip.public_ip]
}