provider "esxi" {
  esxi_hostname      = var.esxi_hostname
  esxi_hostport      = var.esxi_hostport
  esxi_hostssl       = var.esxi_hostssl
  esxi_username      = var.esxi_username
  esxi_password      = var.esxi_password
}

data "template_file" "Default" {
  template = file("userdata.tpl")
}

resource "esxi_guest" "vm" {
  guest_name = "vm-ubuntu"
  disk_store = "Local_Storage"  
  
  memsize  = "2048"
  numvcpus = "2"
  power    = "on"
  guestos = "Ubuntu"
  ovf_source        = var.ovf_file

  network_interfaces {
    virtual_network = "VM Network" 
  }

  guestinfo = {
    "userdata.encoding" = "gzip+base64"
    "userdata"          = base64gzip(data.template_file.Default.rendered)
    }
}

resource "local_file" "ip_address" {
  content  = "[ubuntu]\n${esxi_guest.vm.ip_address}"
  filename = "${path.module}/vm_ip_addresses.ini"
}