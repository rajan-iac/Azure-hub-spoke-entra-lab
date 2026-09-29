output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "hub_vnet_name" {
  value = azurerm_virtual_network.hub_vnet.name
}

output "hub_vnet_id" {
  value = azurerm_virtual_network.hub_vnet.id
}

output "linux_app_private_ip" {
  value = azurerm_network_interface.linux_app_nic.private_ip_address
}