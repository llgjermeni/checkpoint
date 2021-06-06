output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "vnet" {
  value = azurerm_virtual_network.vnet.name
}

output "vnet_location" {
  value = azurerm_virtual_network.vnet.location
}

output "vnet_address_space" {
  value = azurerm_virtual_network.vnet.address_space
}

output "vnet_subnets" {
  value = azurerm_subnet.subnet.*.id
}

output "subnets" {
  value = azurerm_subnet.subnet.*
}

output "subnet_prefixes" {
  value = var.subnet_prefixes
}

output "allocation_method" {
  value = var.allocation_method
}

output  "subnet_names" {
  value = var.subnet_names
}