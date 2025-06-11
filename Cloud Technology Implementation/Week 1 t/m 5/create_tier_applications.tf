data "azurerm_resource_group" "rg" {
  name = "S1204419"
}

output "id" {
  value = data.azurerm_resource_group.rg.id
}

resource "azurerm_virtual_network" "vnet" {
  name                = "network3"
  address_space       = ["10.10.0.0/16"]
  location            = "West Europe"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet_webtier" {
  name                 = "internal_web"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "subnet_datatier" {
  name                 = "internal_data"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.2.0/24"]
}

resource "azurerm_public_ip" "public_ip_webtier" {
  count               = 2
  name                = "web-1${count.index}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_public_ip" "public_ip_datatier" {
  count               = 2
  name                = "data-2${count.index}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_public_ip" "loadbalancer" {
  name                = "loadbalancer-1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "nic_webtier" {
  count               = 2
  name                = "web-nic-${count.index}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal_web"
    subnet_id                     = azurerm_subnet.subnet_webtier.id
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.public_ip_webtier[count.index].id
    private_ip_address            = "10.10.1.1${count.index}"
  }
}

resource "azurerm_storage_account" "storage_account" {
  name                     = "storageaccount2jensban"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Least Redundant Storage, goedkoopst
  account_kind             = "StorageV2"
  access_tier              = "Hot" 
}

resource "azurerm_storage_container" "container" {
  name                  = "blobcontainer"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "blob" 
}

resource "azurerm_network_interface" "nic_datatier" {
  count               = 2
  name                = "data-nic-${count.index}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal_data"
    subnet_id                     = azurerm_subnet.subnet_datatier.id
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.public_ip_datatier[count.index].id
    private_ip_address            = "10.10.2.1${count.index}"
  }
}

resource "azurerm_network_security_group" "nsg_webtier" {
  name                = "nsg-1-allowinbound-tcp-web"
  location            = data.azurerm_resource_group.rg.location
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

  security_rule {
    name                       = "Allow_Inbound_HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "80"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface_security_group_association" "add_webtier" {
  count 	= 2
  network_interface_id      = azurerm_network_interface.nic_webtier[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg_webtier.id
}

resource "azurerm_network_security_group" "nsg_datatier" {
  name                = "nsg-1-allowinbound-tcp-data"
  location            = data.azurerm_resource_group.rg.location
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

resource "azurerm_network_interface_security_group_association" "add_datatier" {
  count 	= 2
  network_interface_id      = azurerm_network_interface.nic_datatier[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg_datatier.id
}

resource "azurerm_linux_virtual_machine" "webtier" {
  count                 = 2
  name                  = "webserver-${count.index + 1}"
  resource_group_name   = data.azurerm_resource_group.rg.name
  location              = data.azurerm_resource_group.rg.location
  size                  = "Standard_B2ats_v2"
  admin_username        = var.ssh_user
  network_interface_ids = [azurerm_network_interface.nic_webtier[count.index].id]

  admin_ssh_key {
    username   = var.ssh_user
    public_key = var.ssh_key
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

   custom_data = base64encode(templatefile("${path.module}/cloudinit/cloud-init.tpl", {
    ssh_username = var.ssh_user
    ssh_key = var.ssh_key
  }))
}

resource "azurerm_linux_virtual_machine" "datatier" {
  count                 = 2
  name                  = "database-${count.index + 1}"
  resource_group_name   = data.azurerm_resource_group.rg.name
  location              = data.azurerm_resource_group.rg.location
  size                  = "Standard_B2ats_v2"
  admin_username        = var.ssh_user
  network_interface_ids = [azurerm_network_interface.nic_datatier[count.index].id]

  admin_ssh_key {
    username   = var.ssh_user
    public_key = var.ssh_key
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
    custom_data = base64encode(templatefile("${path.module}/cloudinit/cloud-init.tpl", {
    ssh_username = var.ssh_user
    ssh_key = var.ssh_key
  }))
}

resource "azurerm_lb" "public_loadbalancer" {
  name                = "public_loadbalancer"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress_Loadbalancer"
    public_ip_address_id = azurerm_public_ip.loadbalancer.id
  }
}

resource "azurerm_lb_backend_address_pool" "public_loadbalancer_backend_address_pool" {
  loadbalancer_id = azurerm_lb.public_loadbalancer.id
  name            = "BackEndAddressPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "nic_webtier" {
  count 	= 2
  network_interface_id    = azurerm_network_interface.nic_webtier[count.index].id
  ip_configuration_name   = "internal_web"
  backend_address_pool_id = azurerm_lb_backend_address_pool.public_loadbalancer_backend_address_pool.id
}

resource "azurerm_lb_probe" "http" {
  loadbalancer_id = azurerm_lb.public_loadbalancer.id
  name            = "http-running-probe"
  port            = 80
}

resource "azurerm_lb_rule" "lbrule-01" {
  loadbalancer_id                = azurerm_lb.public_loadbalancer.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress_Loadbalancer"
  backend_address_pool_ids       =  [azurerm_lb_backend_address_pool.public_loadbalancer_backend_address_pool.id]
  probe_id                       = azurerm_lb_probe.http.id
}

resource "azurerm_lb_rule" "lbrule-02" {
  loadbalancer_id                = azurerm_lb.public_loadbalancer.id
  name                           = "LBRule-02"
  protocol                       = "Udp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress_Loadbalancer"
  backend_address_pool_ids       =  [azurerm_lb_backend_address_pool.public_loadbalancer_backend_address_pool.id]
  probe_id                       = azurerm_lb_probe.http.id
}



resource "local_file" "ip_address" {
  content = <<-EOF
    [webservers]
    ${join("\n", [for ip in azurerm_public_ip.public_ip_webtier : ip.ip_address])}

    [dataservers]
    ${join("\n", [for ip in azurerm_public_ip.public_ip_datatier : ip.ip_address])}

    [all:vars]
    ansible_user=${var.ssh_user}
    ansible_ssh_private_key_file=${var.ssh_key_path}
    ansible_ssh_common_args='-o StrictHostKeyChecking=no'
    become_passwd=
    EOF
  filename = "${path.module}/vm_ip_addresses.ini"
}


# Week 5

# Create a subnet specifically for VMSS
resource "azurerm_subnet" "subnet_vmss" {
  name                 = "internal_vmss"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.3.0/24"]
}

# Network Security Group for VMSS
resource "azurerm_network_security_group" "nsg_vmss" {
  name                = "nsg-vmss-allowinbound-tcp-web"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow_Inbound_SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow_Inbound_HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

# Associate NSG with VMSS subnet
resource "azurerm_subnet_network_security_group_association" "vmss_nsg_association" {
  subnet_id                 = azurerm_subnet.subnet_vmss.id
  network_security_group_id = azurerm_network_security_group.nsg_vmss.id
}

# Public IP for VMSS Load Balancer
resource "azurerm_public_ip" "vmss_lb_public_ip" {
  name                = "vmss-lb-public-ip"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "Production"
  }
}

# Load Balancer for VMSS
resource "azurerm_lb" "vmss_loadbalancer" {
  name                = "vmss-loadbalancer"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "vmss-lb-frontend"
    public_ip_address_id = azurerm_public_ip.vmss_lb_public_ip.id
  }

  tags = {
    environment = "Production"
  }
}

# Backend Address Pool for VMSS Load Balancer
resource "azurerm_lb_backend_address_pool" "vmss_backend_pool" {
  loadbalancer_id = azurerm_lb.vmss_loadbalancer.id
  name            = "vmss-backend-pool"
}

# Health Probe for VMSS Load Balancer
resource "azurerm_lb_probe" "vmss_http_probe" {
  loadbalancer_id = azurerm_lb.vmss_loadbalancer.id
  name            = "vmss-http-probe"
  port            = 80
  protocol        = "Http"
  request_path    = "/"
}

# Load Balancer Rule for VMSS
resource "azurerm_lb_rule" "vmss_lb_rule" {
  loadbalancer_id                = azurerm_lb.vmss_loadbalancer.id
  name                           = "vmss-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "vmss-lb-frontend"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.vmss_backend_pool.id]
  probe_id                       = azurerm_lb_probe.vmss_http_probe.id
}

# Virtual Machine Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "web_vmss" {
  name                = "web-vmss"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = "Standard_B2ats_v2"
  instances           = 2
  admin_username      = var.ssh_user

  # Disable password authentication and use SSH keys
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.ssh_user
    public_key = var.ssh_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.subnet_vmss.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.vmss_backend_pool.id]
    }
  }

  # Cloud-init configuration for web server setup
  custom_data = base64encode(templatefile("${path.module}/cloudinit/cloud-init.tpl", {
    ssh_username = var.ssh_user
    ssh_key      = var.ssh_key
  }))

  tags = {
    environment = "Production"
  }
}

# Autoscale Settings for VMSS
resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  name                = "vmss-autoscale-setting"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.web_vmss.id

  # Default profile 
  profile {
    name = "default-profile"

    capacity {
      default = 2
      minimum = 1
      maximum = 5
    }

    # Scale out rule 
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.web_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    # Scale in rule 
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.web_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  # February profile
  profile {
    name = "february-profile"

    capacity {
      default = 4
      minimum = 3
      maximum = 10
    }

    fixed_date {
      timezone = "W. Europe Standard Time"
      start    = "2025-02-01T00:00:00Z"
      end      = "2025-02-28T23:59:59Z"
    }

    # Scale out February 
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.web_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 60
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "2"
        cooldown  = "PT3M"
      }
    }

    # Scale in rule for February
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.web_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  # Maart
  profile {
    name = "march-profile"

    capacity {
      default = 4
      minimum = 3
      maximum = 10
    }

    fixed_date {
      timezone = "W. Europe Standard Time"
      start    = "2025-03-01T00:00:00Z"
      end      = "2025-03-31T23:59:59Z"
    }

    # Scale out rule 
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.web_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 60
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "2"
        cooldown  = "PT3M"
      }
    }

    # Scale in rule 
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.web_vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = "30"
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  tags = {
    environment = "Production"
  }
}