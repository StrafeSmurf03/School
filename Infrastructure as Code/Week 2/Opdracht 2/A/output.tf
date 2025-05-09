output "webserver_1_ip" {
  value = vsphere_virtual_machine.webserver[0].default_ip_address
  description = "webserver-1"
}

output "webserver_2_ip" {
  value = vsphere_virtual_machine.webserver[1].default_ip_address
  description = "webserver-2"
}

output "database_ip" {
  value = vsphere_virtual_machine.databaseserver.default_ip_address
  description = "database-server"
}

