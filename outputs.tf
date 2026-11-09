
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "virtual_network_name" {
  value = azurerm_virtual_network.vnet.name
}

output "appgateway_subnet_id" {
  value = azurerm_subnet.appgw.id
}

output "backend_subnet_id" {
  value = azurerm_subnet.backend.id
}

output "backend_nsg_name" {
  value = azurerm_network_security_group.backend_nsg.name
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "storage_container_name" {
  value = azurerm_storage_container.uploads.name
}

output "storage_blob_endpoint" {
  value = azurerm_storage_account.storage.primary_blob_endpoint
}

output "application_gateway_public_ip" {
  value = azurerm_public_ip.appgw_ip.ip_address
}

output "application_gateway_name" {
  value = azurerm_application_gateway.appgw.name
}

output "vmss_name" {
  value = azurerm_linux_virtual_machine_scale_set.default.name
}
