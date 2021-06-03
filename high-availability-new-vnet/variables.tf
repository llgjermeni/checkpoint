//********************** Basic Configuration Variables **************************//
variable "cluster_name" {
  description = "Cluster name"
  type = string
}

variable "resource_group_name" {
  description = "Azure Resource Group name to build into"
  type = string
}

variable "resource_group_id" {
  description = "Azure Resource Group ID to use."
  type = string
  default = ""
}

variable "location" {
  description = "The location/region where resources will be created. The full list of Azure regions can be found at https://azure.microsoft.com/regions"
  type = string
}

//********************** Virtual Machine Instances Variables **************************//
variable "availability_type" {
  description = "Specifies whether to deploy the solution based on Azure Availability Set or based on Azure Availability Zone."
  type = string
  default = "Availability Zone"
}

locals { // locals for 'availability_type' allowed values
  availability_type_allowed_values = [
    "Availability Zone",
    "Availability Set"
  ]
  // will fail if [var.availability_type] is invalid:
  validate_availability_type_value = index(local.availability_type_allowed_values, var.availability_type)
}

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

variable "sic_key" {
  description = "Secure Internal Communication(SIC) key"
  type = string
}
resource "null_resource" "sic_key_invalid" {
  count = length(var.sic_key) >= 12 ? 0 : "SIC key must be at least 12 characters long"
}

variable "template_name" {
  description = "Template name. Should be defined according to deployment type(ha, vmss)"
  type = string
  default = "ha_terraform"
}

variable "template_version" {
  description = "Template version. It is reccomended to always use the latest template version"
  type = string
  default = "20210111"
}

variable "installation_type" {
  description = "Installaiton type"
  type = string
  default = "cluster"
}

variable "number_of_vm_instances" {
  description = "Number of VM instances to deploy "
  type = string
  default = "2"
}

variable "publisher" {
  description = "CheckPoint publicher"
  default = "checkpoint"
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

variable "vm_os_offer" {
  description = "The name of the image offer to be deployed.Choose from: check-point-cg-r8030, check-point-cg-r8040, check-point-cg-r81"
  type = string
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

variable "allow_upload_download" {
  description = "Automatically download Blade Contracts and other important data. Improve product experience by sending data to Check Point"
  type = bool
}

variable "is_blink" {
  description = "Define if blink image is used for deployment"
  default = true
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
variable "vnet_name" {
  description = "Virtual Network name"
  type = string
}

variable "vnet_subnets" {
  type = list(string)
}

variable "address_space" {
  description = "The address space that is used by a Virtual Network."
  type = string
  default = "10.0.0.0/16"
}

variable "subnet_prefixes" {
  description = "Address prefix to be used for netwok subnets"
  type = list(string)
  default = [
    "10.0.0.0/24",
    "10.0.1.0/24"]
}

variable "lb_probe_name" {
  description = "Name to be used for lb health probe"
  default = "health_prob_port"
}

variable "lb_probe_port" {
  description = "Port to be used for load balancer health probes and rules"
  default = "8117"
}

variable "lb_probe_protocol" {
  description = "Protocols to be used for load balancer health probes and rules"
  default = "tcp"
}

variable "lb_probe_unhealthy_threshold" {
  description = "Number of times load balancer health probe has an unsuccessful attempt before considering the endpoint unhealthy."
  default = 2
}

variable "lb_probe_interval" {
  description = "Interval in seconds load balancer health probe rule perfoms a check"
  default = 5
}

variable "allocation_method" {
  description = "IP address allocation method"
  type = string
  default = "Static"
}

variable "bootstrap_script" {
  description = "An optional script to run on the initial boot"
  #example:
  #"touch /home/admin/bootstrap.txt; echo 'hello_world' > /home/admin/bootstrap.txt"
}

variable "nsg_id" {
  description = "Network security group to be associated with a Virual Network and subnets"
  type = string
}

//********************** Credentials **************************//
variable "tenant_id" {
  description = "Tenant ID"
  type = string
}

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

variable "sku" {
  description = "SKU"
  type = string
  default = "Standard"
}

variable "enable_custom_metrics" {
  description = "Indicates whether CloudGuard Metrics will be use for Cluster members monitoring."
  type = bool
  default = true
}

//********************** Role Assigments variables**************************//
variable "role_definition" {
  description = "Role definition. The full list of Azure Built-in role descriptions can be found at https://docs.microsoft.com/bs-latn-ba/azure/role-based-access-control/built-in-roles"
  type = string
  default = "Contributor"
}