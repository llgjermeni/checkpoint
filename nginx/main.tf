# resource "azurerm_resource_group" "resource_group" {
#   name = var.resource_group_name
#   location = var.location
# }

locals { // locals for 'next_hop_type' allowed values
  next_hop_type_allowed_values = [
    "VirtualNetworkGateway",
    "VnetLocal",
    "Internet",
    "VirtualAppliance",
    "None"
  ]
}

# resource "azurerm_route_table" "nginx1_route_table" {
#   name = "nginx-route1"
#   location = var.location
#   resource_group_name = var.vnet_rg

#   route {
#     name = "To-Internet"
#     address_prefix = "0.0.0.0/0"
#     next_hop_type = local.next_hop_type_allowed_values[4]
#   }
# }

# resource "azurerm_subnet_route_table_association" "ngnx1_association" {
#   subnet_id = var.vnet_subnets[1]
#   route_table_id = azurerm_route_table.nginx1_route_table.id
# }

resource "azurerm_route_table" "nginx2_route_table" {
  name = "nginx-route2"
  location = var.location
  resource_group_name = var.vnet_rg

  route {
    name = "To-Internet"
    address_prefix = "0.0.0.0/0"
    next_hop_type = local.next_hop_type_allowed_values[4]
  }
}

resource "azurerm_subnet_route_table_association" "ngnx2_association" {
  subnet_id = var.vnet_subnets[2]
  route_table_id = azurerm_route_table.nginx2_route_table.id
}

resource "azurerm_subnet_network_security_group_association" "security_group_frontend_association" {
  depends_on = [var.nsg_id]
  subnet_id = var.vnet_subnets[1]
  network_security_group_id = var.nsg_id
}

resource "azurerm_subnet_network_security_group_association" "security_group_backend_association" {
  depends_on = [var.nsg_id]
  subnet_id = var.vnet_subnets[2]
  network_security_group_id = var.nsg_id
}


resource "azurerm_network_interface" "nic1" {
  depends_on = [
    var.vnet_subnets[1]]
  name = "${var.nginx_name}-eth0"
  location = var.location
  resource_group_name = var.resource_group_name
  enable_ip_forwarding = false

  ip_configuration {
    name = "ipconfig1"
    subnet_id = var.vnet_subnets[1]
    private_ip_address_allocation = var.vnet_allocation_method
    private_ip_address = cidrhost(var.subnet_prefixes[1], 4)
    # public_ip_address_id = azurerm_public_ip.public-ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "security_group_association1" {
  depends_on = [azurerm_network_interface.nic1, var.nsg_id]
  network_interface_id = azurerm_network_interface.nic1.id
  network_security_group_id = var.nsg_id
}

resource "azurerm_network_interface" "nic2" {
    depends_on = [
    var.vnet_subnets[2]
    ]

  name                          = "eth1"
  location                = var.location
  resource_group_name     = var.resource_group_name
  enable_ip_forwarding          = true
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "ipconfig2"
    subnet_id                     = var.vnet_subnets[2]
    private_ip_address_allocation = var.vnet_allocation_method
    private_ip_address            = cidrhost(var.subnet_prefixes[2], 4)
  }
}


resource "azurerm_network_interface_security_group_association" "security_group_association2" {
  depends_on = [azurerm_network_interface.nic2, var.nsg_id]
  network_interface_id = azurerm_network_interface.nic2.id
  network_security_group_id = var.nsg_id
}

//********************** Storage accounts **************************//
// Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = var.resource_group_name
  }
  byte_length = 8
}
resource "azurerm_storage_account" "vm-boot-diagnostics-storage" {
  name = "bootdiag${random_id.randomId.hex}"
  resource_group_name = var.resource_group_name
  location = var.location
  account_tier = var.storage_account_tier
  account_replication_type =var.account_replication_type
  account_kind = "Storage"
}

//********************** Virtual Machines **************************//
locals {
  SSH_authentication_type_condition = var.authentication_type == "SSH Public Key" ? true : false
}

# resource "azurerm_marketplace_agreement" "marketplace" {
#   publisher = var.publisher
#   offer     = var.vm_os_offer
#   plan      = var.vm_os_sku
# }

resource "azurerm_virtual_machine" "nginx-vm-instance" {
  depends_on = [
    azurerm_network_interface.nic1,
    azurerm_network_interface.nic2]
  location = var.location
  name = var.nginx_name
  network_interface_ids = [
    azurerm_network_interface.nic1.id,
    azurerm_network_interface.nic2.id
    ]
  resource_group_name = var.resource_group_name
  vm_size = var.vm_size
  delete_os_disk_on_termination = var.delete_os_disk_on_termination
  primary_network_interface_id = azurerm_network_interface.nic1.id

  identity {
    type = var.vm_instance_identity_type
  }

  # plan {
  #     name = var.vm_os_sku
  #     publisher = var.publisher
  #     product = var.vm_os_offer
  #   }

  boot_diagnostics {
    enabled = var.boot_diagnostics
    storage_uri = var.boot_diagnostics ? join(",", azurerm_storage_account.vm-boot-diagnostics-storage.*.primary_blob_endpoint) : ""
  }

  os_profile {
    computer_name = var.nginx_name
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = local.SSH_authentication_type_condition

    
    dynamic "ssh_keys" {
      for_each = local.SSH_authentication_type_condition ? [
        1] : []
      content {
        path = "/home/notused/.ssh/authorized_keys"
        key_data = file("${path.module}/azure_public_key")
      }
    }
  }

  storage_image_reference {
    publisher = var.publisher
    offer = var.vm_os_offer
    sku = var.vm_os_sku
    version = var.vm_os_version
  }

  storage_os_disk {
    name = var.nginx_name
    create_option = var.storage_os_disk_create_option
    caching = var.storage_os_disk_caching
    managed_disk_type = var.storage_account_type
    disk_size_gb = var.disk_size
  }
}
