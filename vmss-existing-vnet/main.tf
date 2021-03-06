
//********************** Networking **************************//

data "azurerm_subnet" "frontend" {
  name = var.frontend_subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name = var.vnet_resource_group
}

data "azurerm_subnet" "backend" {
  name = var.backend_subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name = var.vnet_resource_group
}

//********************** Load Balancers **************************//
resource "azurerm_public_ip" "public-ip-lb" {
    name = "${var.vmss_name}-app-1"
    location = var.location
    resource_group_name = var.resource_group_name
    allocation_method = var.vnet_allocation_method
    sku = var.sku
}

resource "azurerm_lb" "frontend-lb" {
 name = "frontend-lb"
 location = var.location
 resource_group_name = var.resource_group_name
 sku = var.sku

 frontend_ip_configuration {
   name = "${var.vmss_name}-app-1"
   public_ip_address_id = azurerm_public_ip.public-ip-lb.id
 }
}

resource "azurerm_lb_backend_address_pool" "frontend-lb-pool" {
 loadbalancer_id = azurerm_lb.frontend-lb.id
 name = "${var.vmss_name}-app-1"
 resource_group_name = var.resource_group_name
}

resource "azurerm_lb" "backend-lb" {
 name = "backend-lb"
 location = var.location
 resource_group_name = var.resource_group_name
 sku = var.sku
 frontend_ip_configuration {
   name = "backend-lb"
   subnet_id = data.azurerm_subnet.backend.id
   private_ip_address_allocation = "Static"
   private_ip_address = cidrhost(data.azurerm_subnet.backend.address_prefix,var.backend_lb_IP_address)
 }
}

resource "azurerm_lb_backend_address_pool" "backend-lb-pool" {
  name = "backend-lb-pool"
  loadbalancer_id = azurerm_lb.backend-lb.id
 resource_group_name = var.resource_group_name
}

resource "azurerm_lb_probe" "azure_lb_healprob" {
  depends_on = [azurerm_lb.frontend-lb, azurerm_lb.frontend-lb]
  count = 2
  resource_group_name = var.resource_group_name
  loadbalancer_id = count.index == 0 ? azurerm_lb.frontend-lb.id : azurerm_lb.backend-lb.id
  name = count.index == 0 ? "${var.vmss_name}-app-1" : "backend-lb"
  protocol = var.lb_probe_protocol
  port = var.lb_probe_port
  interval_in_seconds = var.lb_probe_interval
  number_of_probes = var.lb_probe_unhealthy_threshold
}

resource "azurerm_lb_rule" "lbnatrule" {
  depends_on = [azurerm_lb.frontend-lb,azurerm_lb_probe.azure_lb_healprob,azurerm_lb.backend-lb]
  count = 2
  resource_group_name = var.resource_group_name
  loadbalancer_id = count.index == 0 ? azurerm_lb.frontend-lb.id : azurerm_lb.backend-lb.id
  name = count.index == 0 ? "${var.vmss_name}-app-1" : "backend-lb"
  protocol = count.index == 0 ? "Tcp" : "All"
  frontend_port = count.index == 0 ? var.frontend_port : "0"
  backend_port = count.index == 0 ? var.backend_port : "0"
  backend_address_pool_id = count.index == 0 ? azurerm_lb_backend_address_pool.frontend-lb-pool.id : azurerm_lb_backend_address_pool.backend-lb-pool.id
  frontend_ip_configuration_name = count.index == 0 ? azurerm_lb.frontend-lb.frontend_ip_configuration[0].name : azurerm_lb.backend-lb.frontend_ip_configuration[0].name
  probe_id = azurerm_lb_probe.azure_lb_healprob[count.index].id
  load_distribution = count.index == 0 ? var.frontend_load_distribution : var.backend_load_distribution
}

//********************** Storage accounts **************************//
// Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
         resource_group_name = var.resource_group_name
    }
    byte_length = 8
}
resource "azurerm_storage_account" "vm-boot-diagnostics-storage" {
    name = "diag${random_id.randomId.hex}"
    resource_group_name = var.resource_group_name
    location = var.location
    account_tier = var.storage_account_tier
    account_replication_type = var.account_replication_type

}

//********************** Virtual Machines **************************//
locals {
  SSH_authentication_type_condition = var.authentication_type == "SSH Public Key" ? true : false
  availability_zones_num_condition = var.availability_zones_num == "0" ? ["0"] : var.availability_zones_num == "1" ? ["1"] : var.availability_zones_num == "2" ? ["1", "2"] : ["1", "2", "3"]
  custom_image_condition = var.source_image_vhd_uri == "noCustomUri" ? false : true
  management_interface_name = split("-", var.management_interface)[0]
  management_ip_address_type = split("-", var.management_interface)[1]
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

resource "azurerm_virtual_machine_scale_set" "vmss" {
  depends_on = [
    azurerm_marketplace_agreement.marketplace]
  name = var.vmss_name
  location = var.location
  resource_group_name = var.resource_group_name
  zones = local.availability_zones_num_condition
  overprovision = false

  dynamic "identity" {
    for_each = var.enable_custom_metrics ? [
      1] : []
    content {
      type = "SystemAssigned"
    }
  }

  storage_profile_image_reference {
    id = local.custom_image_condition ? azurerm_image.custom-image[0].id : null
    publisher = local.custom_image_condition ? null : var.publisher
    offer = var.vm_os_offer
    sku = var.vm_os_sku
    version = var.vm_os_version
  }

  storage_profile_os_disk {
    create_option = var.storage_os_disk_create_option
    caching = var.storage_os_disk_caching
    managed_disk_type = var.storage_account_type
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

  os_profile {
    computer_name_prefix  = var.vmss_name
    admin_username = var.admin_username
    admin_password = var.admin_password
    custom_data = templatefile("${path.module}/cloud-init.sh",{
      installation_type=var.installation_type
      allow_upload_download= var.allow_upload_download
      os_version=var.os_version
      template_name=var.template_name
      template_version=var.template_version
      is_blink=var.is_blink
      bootstrap_script64=base64encode(var.bootstrap_script)
      location=var.location
      sic_key=var.sic_key
      vnet=data.azurerm_subnet.frontend.address_prefix
      enable_custom_metrics=var.enable_custom_metrics ? "yes" : "no"
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

  boot_diagnostics {
    enabled = var.boot_diagnostics
    storage_uri = var.boot_diagnostics ? join(",", azurerm_storage_account.vm-boot-diagnostics-storage.*.primary_blob_endpoint) : ""
  }

  upgrade_policy_mode = "Manual"

  network_profile {
     name = "eth0"
     primary = true
     ip_forwarding = false
     accelerated_networking = true
     ip_configuration {
       name = "ipconfig1"
       subnet_id = data.azurerm_subnet.frontend.id
       load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.frontend-lb-pool.id]
       primary = true
     }
 }

  network_profile {
     name = "eth1"
     primary = false
     ip_forwarding = true
     accelerated_networking = true
     ip_configuration {
       name = "ipconfig2"
       subnet_id = data.azurerm_subnet.backend.id
       load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend-lb-pool.id]
       primary = true
     }
 }
  sku {
    capacity = var.number_of_vm_instances
    name = var.vm_size
    tier = "Standard"
  }

  tags = var.management_interface == "eth0"?{
    x-chkp-management = var.management_name,
    x-chkp-template = var.configuration_template_name,
    x-chkp-ip-address = local.management_ip_address_type,
    x-chkp-management-interface = local.management_interface_name,
    x-chkp-management-address = var.management_IP,
    x-chkp-topology = "eth0:external,eth1:internal",
    x-chkp-anti-spoofing = "eth0:false,eth1:false",
    x-chkp-srcImageUri = var.source_image_vhd_uri
  }:{
    x-chkp-management = var.management_name,
    x-chkp-template = var.configuration_template_name,
    x-chkp-ip-address = local.management_ip_address_type,
    x-chkp-management-interface = local.management_interface_name,
    x-chkp-topology = "eth0:external,eth1:internal",
    x-chkp-anti-spoofing = "eth0:false,eth1:false",
    x-chkp-srcImageUri = var.source_image_vhd_uri
  }
}

resource "azurerm_monitor_autoscale_setting" "vmss_settings" {
  depends_on = [azurerm_virtual_machine_scale_set.vmss]
  name = var.vmss_name
  resource_group_name = var.resource_group_name
  location = var.location
  target_resource_id  = azurerm_virtual_machine_scale_set.vmss.id

  profile {
    name = "Profile1"

    capacity {
      default = var.number_of_vm_instances
      minimum = var.minimum_number_of_vm_instances
      maximum = var.maximum_number_of_vm_instances
    }

    rule {
      metric_trigger {
        metric_name = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.vmss.id
        time_grain = "PT1M"
        statistic = "Average"
        time_window = "PT5M"
        time_aggregation = "Average"
        operator = "GreaterThan"
        threshold = 80
      }

      scale_action {
        direction = "Increase"
        type = "ChangeCount"
        value = "1"
        cooldown = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.vmss.id
        time_grain = "PT1M"
        statistic = "Average"
        time_window = "PT5M"
        time_aggregation = "Average"
        operator = "LessThan"
        threshold = 60
      }

      scale_action {
        direction = "Decrease"
        type = "ChangeCount"
        value = "1"
        cooldown = "PT5M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator = false
      send_to_subscription_co_administrator = false
      custom_emails = var.notification_email == "" ? [] : [var.notification_email]
    }
  }
}

resource "azurerm_role_assignment" "custom_metrics_role_assignment"{
  depends_on = [azurerm_virtual_machine_scale_set.vmss]
  count = var.enable_custom_metrics ? 1 : 0
  role_definition_id = join("", ["/subscriptions/", var.subscription_id, "/providers/Microsoft.Authorization/roleDefinitions/", "3913510d-42f4-4e42-8a64-420c390055eb"])
  principal_id = lookup(azurerm_virtual_machine_scale_set.vmss.identity[0], "principal_id")
  scope = var.resource_group_id
  lifecycle {
    ignore_changes = [
      role_definition_id, principal_id
    ]
  }
}