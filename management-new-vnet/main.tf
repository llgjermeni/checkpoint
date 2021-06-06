//********************** Providers **************************//

resource "azurerm_public_ip" "public-ip" {
  name = var.mgmt_name
  location = var.location
  resource_group_name = var.resource_group_name
  allocation_method = var.vnet_allocation_method
  idle_timeout_in_minutes = 30
  domain_name_label = join("", [
    var.mgmt_name,
    "-",
    random_id.randomId.hex])
}

resource "azurerm_subnet_network_security_group_association" "security_group_frontend_association" {
  depends_on = [var.vnet, var.subnet[0]]
  subnet_id = var.vnet_subnets[0]
  network_security_group_id = var.nsg_id
}

resource "azurerm_subnet_network_security_group_association" "security_group_backend_association" {
  depends_on = [var.vnet, var.subnet[1]]
  subnet_id = var.subnets_id[1]
  network_security_group_id = var.nsg_id
}

resource "azurerm_network_interface" "nic" {
  depends_on = [
    azurerm_public_ip.public-ip]
  name = "${var.mgmt_name}-eth0"
  location = var.location
  resource_group_name = var.resource_group_name
  enable_ip_forwarding = false

  ip_configuration {
    name = "ipconfig1"
    subnet_id = var.vnet_subnets[0]
    private_ip_address_allocation = var.vnet_allocation_method
    private_ip_address = cidrhost(var.subnet_prefix, 4)
    public_ip_address_id = azurerm_public_ip.public-ip.id
  }
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
  custom_image_condition = var.source_image_vhd_uri == "noCustomUri" ? false : true
}

resource "azurerm_image" "custom-image" {
  count = local.custom_image_condition ? 1 : 0
  name = "custom-image"
  location = var.location
  resource_group_name = var.resource_group_name

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = var.source_image_vhd_uri
  }
}

resource "azurerm_marketplace_agreement" "marketplace" {
  publisher = var.publisher
  offer     = var.vm_os_offer
  plan      = var.vm_os_sku
}

resource "azurerm_virtual_machine" "mgmt-vm-instance" {
  depends_on = [
    azurerm_network_interface.nic,
    azurerm_marketplace_agreement.marketplace]
  location = var.location
  name = var.mgmt_name
  network_interface_ids = [
    azurerm_network_interface.nic.id]
  resource_group_name = var.resource_group_name
  vm_size = var.vm_size
  delete_os_disk_on_termination = var.delete_os_disk_on_termination
  primary_network_interface_id = azurerm_network_interface.nic.id

  identity {
    type = var.vm_instance_identity_type
  }

  dynamic "plan" {
    for_each = local.custom_image_condition ? [
    ] : [1]
    content {
      name = var.vm_os_sku
      publisher = var.publisher
      product = var.vm_os_offer
    }
  }

  boot_diagnostics {
    enabled = var.boot_diagnostics
    storage_uri = var.boot_diagnostics ? join(",", azurerm_storage_account.vm-boot-diagnostics-storage.*.primary_blob_endpoint) : ""
  }

  os_profile {
    computer_name = var.mgmt_name
    admin_username = var.admin_username
    admin_password = var.admin_password
    custom_data = templatefile("${path.module}/cloud-init.sh", {
      installation_type = var.installation_type
      allow_upload_download = var.allow_upload_download
      os_version = var.os_version
      template_name = var.template_name
      template_version = var.template_version
      is_blink = var.is_blink
      bootstrap_script64 = base64encode(var.bootstrap_script)
      location = var.location
      management_GUI_client_network = var.management_GUI_client_network
    })
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
    id = local.custom_image_condition ? azurerm_image.custom-image[0].id : null
    publisher = local.custom_image_condition ? null : var.publisher
    offer = var.vm_os_offer
    sku = var.vm_os_sku
    version = var.vm_os_version
  }

  storage_os_disk {
    name = var.mgmt_name
    create_option = var.storage_os_disk_create_option
    caching = var.storage_os_disk_caching
    managed_disk_type = var.storage_account_type
    disk_size_gb = var.disk_size
  }
}
