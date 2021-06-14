
## Deploy the module Single existing vnet

I have uploaded the code inside my github repo to make the testing like the real deployment that the client may use. If you fork the repo in your github repo then you need to change the source of module. This module need to create vnet and 2 subnet before you make the deployment. Change the naming of these inside the module "checkpoint-single-existing-vnet".

In the provider section enter the details needed for authentication. 

You can copy paste this code without any change and run terraform commands.



```Terraform
//********************** Providers **************************//
provider "azurerm" {
   subscription_id = "xxxxxxxxxxxxx"
   client_id       = "xxxxxxxxxxx"
   client_secret   = "xxxxxxxxxxxx"
   tenant_id       = "xxxxxxxxxxxxx"

  features {}
}

//********************** Basic Configuration **************************//
module "common" {
  source                 = "github.com/llgjermeni/checkpoint/modules/common"
  
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
  tags                   = {

  }         
}


//********************** Single existing vnet**************************//
module "checkpoint-single-existing-vnet" {
  source                        = "github.com/llgjermeni/checkpoint/checkpoint-single-existing-vnet"
  
  # enter your subscription_id 
  subscription_id               = "xxxxxxxxxxxxxxxxx" # "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  
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
  installation_type             = "gateway"  
 
  ############------Networking-------###################
  # Create an azure vnet with 2 subnet.  
  vnet_name                     = "check-vnet"              # "checkpoint-mgmt-vnet"
  vnet_rg                       = "network-rg"
  subnet_name1                  = "Frontend"
  subnet_name2                  = "Backend"
  management_GUI_client_network = "0.0.0.0/0"                    # "0.0.0.0/0"
}


```

