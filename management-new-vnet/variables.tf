//********************** Basic Configuration Variables **************************//
variable "mgmt_name" {
  description = "Management name"
  type = string
}

variable "resource_group_name" {
  description = "Azure Resource Group name to build into"
  type = string
}

variable "location" {
  description = "The location/region where resource will be created. The full list of Azure regions can be found at https://azure.microsoft.com/regions"
  type = string
}

//********************** Virtual Machine Instances Variables **************************//
variable "source_image_vhd_uri" {
  type = string
  description = "The URI of the blob containing the development image. Please use noCustomUri if you want to use marketplace images."
  default = "noCustomUri"
}

variable "admin_username" {
  description = "Administrator username of deployed VM. Due to Azure limitations 'notused' name can be used"
  default = "notused"
}

variable "admin_password" {
  description = "Administrator password of deployed Virtual Macine. The password must meet the complexity requirements of Azure"
  type = string
}

variable "boot_diagnostics" {
  type        = bool
  description = "Enable or Disable boot diagnostics"
  default     = true
}

variable "authentication_type" {
  description = "Specifies whether a password authentication or SSH Public Key authentication should be used"
  type = string
}
locals { // locals for 'authentication_type' allowed values
  authentication_type_allowed_values = [
    "Password",
    "SSH Public Key"
  ]
  // will fail if [var.authentication_type] is invalid:
  validate_authentication_type_value = index(local.authentication_type_allowed_values, var.authentication_type)
}
variable "template_name" {
  description = "Template name. Should be defined according to deployment type(mgmt, ha, vmss)"
  type = string
  default = "mgmt_terraform"
}

variable "template_version" {
  description = "Template version. It is reccomended to always use the latest template version"
  type = string
  default = "20210111"
}

variable "installation_type" {
  description = "Installaiton type"
  type = string
  default = "management"
}

locals { // locals for 'installation_type' allowed values
  installation_type_allowed_values = [
    "custom",
    "management"
  ]
  // will fail if [var.installation_type] is invalid:
  validate_installation_type_value = index(local.installation_type_allowed_values, var.installation_type)
}

variable "vm_size" {
  description = "Specifies size of Virtual Machine"
  type = string
}

variable "disk_size" {
  description = "Storage data disk size size(GB).Select a number between 100 and 3995"
  type = string
}

variable "vm_os_version" {
  description = "The version of the image that you want to deploy. "
  type = string
  default = "latest"
}

variable "os_version" {
  description = "GAIA OS version"
  type = string
}

variable "vm_os_offer" {
  description = "The name of the image offer to be deployed.Choose from: check-point-cg-r8030, check-point-cg-r8040, check-point-cg-r81"
  type = string
}

variable "vm_os_sku" {
  /*
    Choose from:
      - "sg-byol"
      - "sg-ngtp-v2" (for R80.30 only)
      - "sg-ngtx-v2" (for R80.30 only)
      - "sg-ngtp" (for R80.40 and above)
      - "sg-ngtx" (for R80.40 and above)
      - "mgmt-byol"
      - "mgmt-25"
  */
  description = "The sku of the image to be deployed"
  type = string
}

locals { // locals for 'vm_os_sku' allowed values
  vm_os_sku_allowed_values = [
    "sg-byol",
    "sg-ngtp",
    "sg-ngtx",
    "sg-ngtp-v2",
    "sg-ngtx-v2",
    "mgmt-byol",
    "mgmt-25"
  ]
  // will fail if [var.vm_os_sku] is invalid:
  validate_vm_os_sku_value = index(local.vm_os_sku_allowed_values, var.vm_os_sku)
}

variable "publisher" {
  description = "CheckPoint publicher"
  default = "checkpoint"
}

variable "allow_upload_download" {
  description = "Automatically download Blade Contracts and other important data. Improve product experience by sending data to Check Point"
  type = bool
}

variable "is_blink" {
  description = "Define if blink image is used for deployment"
}

variable "storage_account_tier" {
  description = "Defines the Tier to use for this storage account.Valid options are Standard and Premium"
  default = "Standard"
}

locals { // locals for 'storage_account_tier' allowed values
  storage_account_tier_allowed_values = [
   "Standard",
   "Premium"
  ]
  // will fail if [var.storage_account_tier] is invalid:
  validate_storage_account_tier_value = index(local.storage_account_tier_allowed_values, var.storage_account_tier)
}

variable "account_replication_type" {
  description = "Defines the type of replication to use for this storage account.Valid options are LRS, GRS, RAGRS and ZRS"
  type = string
  default = "LRS"
}

locals { // locals for 'account_replication_type' allowed values
  account_replication_type_allowed_values = [
   "LRS",
   "GRS",
   "RAGRS",
   "ZRS"
  ]
  // will fail if [var.account_replication_type] is invalid:
  validate_account_replication_type_value = index(local.account_replication_type_allowed_values, var.account_replication_type)
}

variable "delete_os_disk_on_termination" {
  type        = bool
  description = "Delete datadisk when VM is terminated"
  default     = true
}

variable "vm_instance_identity_type" {
  description = "Managed Service Identity type"
  type = string
  default = "SystemAssigned"
}

variable "storage_account_type" {
  description = "Defines the type of storage account to be created. Valid options is Standard_LRS, Premium_LRS"
  type = string
  default     = "Standard_LRS"
}

locals { // locals for 'storage_account_type' allowed values
  storage_account_type_allowed_values = [
    "Standard_LRS",
    "Premium_LRS"
  ]
  // will fail if [var.storage_account_type] is invalid:
  validate_storage_account_type_value = index(local.storage_account_type_allowed_values, var.storage_account_type)
}

//************** Storage OS disk variables **************//
variable "storage_os_disk_create_option" {
  description = "The method to use when creating the managed disk"
  type = string
  default = "FromImage"
}

variable "storage_os_disk_caching" {
  description = "Specifies the caching requirements for the OS Disk"
  default = "ReadWrite"
}

//********************** Natworking Variables **************************//
# variable "vnet_name" {
#   description = "Virtual Network name"
#   type = string
# }

variable "vnet_subnets" {
  type = list(string)
}

# variable "address_space" {
#   description = "The address space that is used by a Virtual Network."
#   type = string
#   default = "10.0.0.0/16"
# }

variable "subnet_prefix" {
  description = "Address prefix to be used for network subnet"
  type = string
  default = "10.0.0.0/24"
}

variable "vnet_allocation_method" {
  description = "IP address allocation method"
  type = string
  default = "Static"
}

variable "management_GUI_client_network" {
  description = "Allowed GUI clients - GUI clients network CIDR"
  type = string
}

locals {
  regex_valid_management_GUI_client_network = "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(/(3[0-2]|2[0-9]|1[0-9]|[0-9]))$"
  // Will fail if var.management_GUI_client_network is invalid
  regex_management_GUI_client_network = regex(local.regex_valid_management_GUI_client_network, var.management_GUI_client_network) == var.management_GUI_client_network ? 0 : "Variable [management_GUI_client_network] must be a valid IPv4 network CIDR."

  regex_valid_network_cidr = "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(/(3[0-2]|2[0-9]|1[0-9]|[0-9]))|$"
  // Will fail if var.address_space is invalid
  # regex_address_space = regex(local.regex_valid_network_cidr, var.address_space) == var.address_space ? 0 : "Variable [address_space] must be a valid address in CIDR notation."
  // Will fail if var.subnet_prefix is invalid
  regex_subnet_prefix = regex(local.regex_valid_network_cidr, var.subnet_prefix) == var.subnet_prefix ? 0 : "Variable [subnet_prefix] must be a valid address in CIDR notation."
}

variable "bootstrap_script" {
  description = "An optional script to run on the initial boot"
  default = ""
  type = string
  #example:
  #"touch /home/admin/bootstrap.txt; echo 'hello_world' > /home/admin/bootstrap.txt"
}

variable "nsg_id" {
  description = "Network security group to be associated with a Virual Network and subnets"
  type = string
}
//********************** Credentials **************************//
# variable "tenant_id" {
#   description = "Tenant ID"
#   type = string
# }

# variable "subscription_id" {
#   description = "Subscription ID"
#   type = string
# }

# variable "client_id" {
#   description = "Aplication ID(Client ID)"
#   type = string
# }

# variable "client_secret" {
#   description = "A secret string that the application uses to prove its identity when requesting a token. Also can be referred to as application password."
#   type = string
# }
