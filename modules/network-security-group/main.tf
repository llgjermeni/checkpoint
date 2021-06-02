resource "azurerm_network_security_group" "nsg" {
  name = var.security_group_name
  location = var.location
  resource_group_name = var.resource_group_name
  tags = var.tags
  }

# locals {
#   nsg_condition = var.nsg_id == null ? false : true
# }

resource "azurerm_subnet_network_security_group_association" "security_group_frontend_association" {
  # count               = local.nsg_condition ? 1 : 0
  # depends_on = [var.vnet_name, var.subnet_names[0]]
  subnet_id = var.subnet_id[0]
  network_security_group_id = azurerm_network_security_group.nsg.id
}
resource "azurerm_subnet_network_security_group_association" "security_group_backend_association" {
  count = length(var.subnet_id) >= 2 ? 1 : 0
  # depends_on = [var.vnet, var.subnet_names[1]]
  subnet_id = var.subnet_id[1]
  network_security_group_id = azurerm_network_security_group.nsg.id
}

//************ Security Rule Example **************//
resource "azurerm_network_security_rule" "security_rule" {
  count = length(var.security_rules)
  name = lookup(var.security_rules[count.index], "name")
  priority = lookup(var.security_rules[count.index], "priority", 4096 - length(var.security_rules) + count.index)
  direction = lookup(var.security_rules[count.index], "direction")
  access = lookup(var.security_rules[count.index], "access")
  protocol = lookup(var.security_rules[count.index], "protocol")
  source_port_range = lookup(var.security_rules[count.index], "source_port_ranges")
  destination_port_range = lookup(var.security_rules[count.index], "destination_port_ranges")
  description = lookup(var.security_rules[count.index], "description")
  source_address_prefix = lookup(var.security_rules[count.index], "source_address_prefix")
  destination_address_prefix = lookup(var.security_rules[count.index], "destination_address_prefix")
  resource_group_name = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}
