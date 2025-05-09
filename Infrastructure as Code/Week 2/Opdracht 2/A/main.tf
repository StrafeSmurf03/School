data "vsphere_datacenter" "dc" {
    name = "ha-datacenter"
}

data "vsphere_host" "host" {
  name          = "192.168.1.10"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}


# Naam van datastore in esxi.
data "vsphere_datastore" "datastore" {
    name = "Local_Storage"
    datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {}

data "vsphere_network" "mgmt_lan" {
    name = "VM Network"
    datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "webserver" {
    count = 2
    name = "webserver-${count.index + 1}"
    resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
    datacenter_id = "${data.vsphere_datacenter.dc.id}"
    datastore_id = "${data.vsphere_datastore.datastore.id}"
    host_system_id = "${data.vsphere_host.host.id}"
    num_cpus = 1
    memory = 2048
    wait_for_guest_ip_timeout = 5
    guest_id = "ubuntu64Guest"
    
    ovf_deploy {
        allow_unverified_ssl_cert = false
        remote_ovf_url = "http://cloud-images-archive.ubuntu.com/releases/noble/release-20240423/ubuntu-24.04-server-cloudimg-amd64.ova"
        disk_provisioning = "thin"
    }

    network_interface {
        network_id     = "${data.vsphere_network.mgmt_lan.id}"
    }

    disk {
        label = "Hard Disk 1"
        size = 16
        thin_provisioned = true
    }

    extra_config = {
    "userdata.encoding" = "base64"
    "userdata"          = base64encode(templatefile("${path.module}/cloudinit/user-data.tpl", {
      username = var.ssh_username
      ssh_key  = var.ssh_key
    }))
  }
}

resource "vsphere_virtual_machine" "databaseserver" {
    name = "databaseserver"
    resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
    datacenter_id = "${data.vsphere_datacenter.dc.id}"
    datastore_id = "${data.vsphere_datastore.datastore.id}"
    host_system_id = "${data.vsphere_host.host.id}"
    num_cpus = 1
    memory = 2048
    wait_for_guest_ip_timeout = 5
    guest_id = "ubuntu64Guest"
    
    ovf_deploy {
        allow_unverified_ssl_cert = false
        remote_ovf_url = "http://cloud-images-archive.ubuntu.com/releases/noble/release-20240423/ubuntu-24.04-server-cloudimg-amd64.ova"
        disk_provisioning = "thin"
    }

    network_interface {
        network_id     = "${data.vsphere_network.mgmt_lan.id}"
        adapter_type   = "vmxnet3"
    }

    disk {
        label = "Hard Disk 1"
        size = 16
        thin_provisioned = true
    }

    extra_config = {
    "userdata.encoding" = "base64"
    "userdata"          = base64encode(templatefile("${path.module}/cloudinit/user-data.tpl", {
      username = var.ssh_username
      ssh_key  = var.ssh_key
    }))
  }
}

resource "local_file" "outputs" {
  content = <<-EOT
    Webserver 1 IP: ${vsphere_virtual_machine.webserver[0].default_ip_address}
    Webserver 2 IP: ${vsphere_virtual_machine.webserver[1].default_ip_address}
    Database IP: ${vsphere_virtual_machine.databaseserver.default_ip_address}
  EOT
  filename = "${path.module}/vm_info.txt"
}