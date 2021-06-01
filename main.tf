//********************** Providers **************************//
provider "azurerm" {
  # subscription_id = var.subscription_id
  # client_id       = var.client_id
  # client_secret   = var.client_secret
  # tenant_id       = var.tenant_id

  features {}
}

//********************** Basic Configuration **************************//
module "common" {
  source                 = "./modules/common"
  
  resource_group_name    = "checkpoint-rg"
  location               = "eastus"
  admin_password         = "Hollywood@2020"                       # "xxxxxxxxxxxx"
  allow_upload_download  = true
  vm_size                = "Standard_D3_v2"                       # "Standard_D3_v2"
  disk_size              = "110"                                  # "110"
  vm_os_sku              = "sg-byol"                              # "mgmt-byol"
  vm_os_offer            = "check-point-cg-r8040"                 # "check-point-cg-r8030"
  os_version             = "R80.40"                               # "R80.30"
  authentication_type    = "Password"                                # "Password"
  is_blink               = true   
  number_of_vm_instances = 1     
  template_version       = "20210126"  
  template_name          = "single_terraform"    
  installation_type      = "gateway"  
  tags                   = {

  }         
}

//********************** Networking **************************//
# module "vnet" {
#   source              = "./modules/vnet"

#   vnet_name           = "checkpoint-vnet"             
#   resource_group_name = module.common.resource_group_name
#   location            = module.common.resource_group_location
#   nsg_id              = null
#   address_space       = "10.0.0.0/16"
#   subnet_names        = ["Frontend","Backend"]
#   subnet_prefixes     = ["10.0.0.0/24", "10.0.1.0/24"]
# }

//********************** Single new vnet**************************//
# module "checkpoint-single-new-vnet" {
#     source                        = "./checkpoint-single"

#     subscription_id               = "67cbc60e-2a29-4cb3-a515-c24a5cb35dbb" # "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
#     source_image_vhd_uri          = "noCustomUri"                          # "noCustomUri"
#     resource_group_name           = module.common.resource_group_name
#     location                      = module.common.resource_group_location
#     sg_name                       = "sg-machine"                           # "checkpoint-mgmt-terraform"
    # admin_password                = module.common.admin_password                       # "xxxxxxxxxxxx"
    # vm_size                       = module.common.vm_size                       # "Standard_D3_v2"
    # disk_size                     = module.common.disk_size                                  # "110"
    # vm_os_sku                     = module.common.vm_os_sku                              # "mgmt-byol"
    # vm_os_offer                   = module.common.vm_os_offer                 # "check-point-cg-r8030"
    # os_version                    = module.common.os_version                               # "R80.30"
    # bootstrap_script              = ""                                     # "touch /home/admin/bootstrap.txt; echo 'hello_world' > /home/admin/bootstrap.txt"
    # allow_upload_download         = module.common.allow_upload_download                                   # true
    # authentication_type           = module.common.authentication_type                             # "Password"
#     enable_custom_metrics         = true                                   # true
#     is_blink                      = module.common.is_blink                          
#     sic_key                       = "hollywood123456789"                   # "xxxxxxxxxxxx"
#     resource_group_id             = module.common.resource_group_id
#     subnet_id                     = module.vnet.vnet_subnets
#     management_GUI_client_network = "0.0.0.0/0"                    # "0.0.0.0/0"
# }

//********************** Single existing vnet**************************//
module "checkpoint-single-existing-vnet" {
  source                        = "./checkpoint-single-existing-vnet"
  
  subscription_id               = "47f1c351-5c94-463e-8bca-cdf6bca35321" # "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  source_image_vhd_uri          = "noCustomUri"                          # "noCustomUri"
  resource_group_name           = module.common.resource_group_name
  location                      = module.common.resource_group_location
  sg_name                       = "sg-machine"                           # "checkpoint-mgmt-terraform"
  admin_password                = module.common.admin_password                       # "xxxxxxxxxxxx"
  vm_size                       = module.common.vm_size                       # "Standard_D3_v2"
  disk_size                     = module.common.disk_size                                  # "110"
  vm_os_sku                     = module.common.vm_os_sku                              # "mgmt-byol"
  vm_os_offer                   = module.common.vm_os_offer                 # "check-point-cg-r8030"
  os_version                    = module.common.os_version                               # "R80.30"
  bootstrap_script              = ""                                     # "touch /home/admin/bootstrap.txt; echo 'hello_world' > /home/admin/bootstrap.txt"
  allow_upload_download         = module.common.allow_upload_download                                   # true
  authentication_type           = module.common.authentication_type                             # "Password"
  enable_custom_metrics         = true                                   # true
  sic_key                       = "hollywood123456789"                   # "xxxxxxxxxxxx"
  resource_group_id             = module.common.resource_group_id
  is_blink                      = module.common.is_blink
  installation_type             = module.common.installation_type  
  ############------Networking-------###################
  vnet_name                     = "check-vnet"              # "checkpoint-mgmt-vnet"
  vnet_rg                       = "network-rg"
  subnet_name1                  = "Frontend"
  subnet_name2                  = "Backend"
  management_GUI_client_network = "0.0.0.0/0"                    # "0.0.0.0/0"
}