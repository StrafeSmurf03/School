# Deployment off ubuntu machine to a single esxi server!

data "vsphere_datacenter" "dc" {
    name = "ha-datacenter"
}

data "vsphere_host" "host" {
  name          = "192.168.1.10"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}


# Name of datastore in esxi.
data "vsphere_datastore" "datastore" {
    name = "Local_Storage"
    datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_resource_pool" "pool" {}

data "vsphere_network" "mgmt_lan" {
    name = "VM Network"
    datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "vm" {
    name = "ubuntumachine1"
    resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
    datacenter_id = "${data.vsphere_datacenter.dc.id}"
    datastore_id = "${data.vsphere_datastore.datastore.id}"
    host_system_id = "${data.vsphere_host.host.id}"
    num_cpus = 1
    memory = 1024
    wait_for_guest_net_timeout = 0
    guest_id = "otherLinux64Guest"
    
    ovf_deploy {
        allow_unverified_ssl_cert = false
        remote_ovf_url = "https://cloud-images.ubuntu.com/noble/20250228/noble-server-cloudimg-amd64.ova"
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
}