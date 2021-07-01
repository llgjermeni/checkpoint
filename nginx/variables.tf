//********************** Basic Configuration Variables **************************//
variable "nginx_name" {
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

variable "admin_username" {
  description = "Administrator username of deployed VM. Due to Azure limitations 'notused' name can be used"
  default = "vm-admin"
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

variable "vm_os_offer" {
  description = "The name of the image offer to be deployed.Choose from: check-point-cg-r8030, check-point-cg-r8040, check-point-cg-r81"
  type = string
  default = "nginx-14-05-2021"
}

variable "vm_os_sku" {
  description = "The sku of the image to be deployed"
  type = string
  default = "nginx"
}


variable "publisher" {
  description = "CheckPoint publicher"
  default = "nilespartnersinc1617691698386"
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
variable "vnet_rg" {
  description = "Virtual Network RG"
  type = string
}

variable "vnet_subnets" {
  type = list(string)
}

# variable "address_space" {
#   description = "The address space that is used by a Virtual Network."
#   type = string
#   default = "10.0.0.0/16"
# }

variable "subnet_prefixes" {
  description = "Address prefix to be used for network subnet"
  type = list(string)
}

variable "vnet_allocation_method" {
  description = "IP address allocation method"
  type = string
  default = "Static"
}


locals {
  regex_valid_network_cidr = "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(/(3[0-2]|2[0-9]|1[0-9]|[0-9]))|$"
  // Will fail if var.address_space is invalid
  # regex_address_space = regex(local.regex_valid_network_cidr, var.address_space) == var.address_space ? 0 : "Variable [address_space] must be a valid address in CIDR notation."
  // Will fail if var.subnet_prefix is invalid
  # regex_subnet_prefix = regex(local.regex_valid_network_cidr, var.subnet_prefixes) == var.subnet_prefixes ? 0 : "Variable [subnet_prefixes] must be a valid address in CIDR notation."
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
