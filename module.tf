resource azurerm_availability_set availabilityset {
  count                        = var.deploy ? 1 : 0
  name                         = "${local.prefix}-as"
  location                     = var.location
  resource_group_name          = var.resourceGroup.name
  platform_fault_domain_count  = "2"
  platform_update_domain_count = "3"
  managed                      = "true"
  tags                         = var.tags
}

module "dc1" {
  source            = "github.com/canada-ca-terraform-modules/terraform-azurerm-caf-windows_virtual_machine?ref=v1.0.2"
  deploy            = var.deploy
  env               = var.env
  serverType        = "SRV"
  userDefinedString = var.userDefinedString
  postfix           = "01"
  location          = var.resourceGroup.location
  resource_group    = var.resourceGroup
  subnetName        = var.subnet
  nic_ip_configuration = {
    private_ip_address            = [var.rootDC1IPAddress]
    private_ip_address_allocation = ["Static"]
  }
  asg                  = var.asg
  dnsServers           = var.dnsServers
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  priority             = var.priority
  data_disk_sizes_gb   = [10]
  os_managed_disk_type = var.managed_disk_type
  vm_size              = var.vm_size
  license_type         = "Windows_Server"
  availability_set_id  = var.deploy ? azurerm_availability_set.availabilityset[0].id : null
  monitoringAgent      = var.monitoringAgent
  dependancyAgent      = var.dependancyAgent
  public_ip            = false
  tags                 = var.tags
}

module "dc2" {
  source            = "github.com/canada-ca-terraform-modules/terraform-azurerm-caf-windows_virtual_machine?ref=v1.0.2"
  deploy            = var.deploy
  env               = var.env
  serverType        = "SRV"
  userDefinedString = var.userDefinedString
  postfix           = "02"
  location          = var.resourceGroup.location
  resource_group    = var.resourceGroup
  subnetName        = var.subnet
  nic_ip_configuration = {
    private_ip_address            = [var.rootDC2IPAddress]
    private_ip_address_allocation = ["Static"]
  }
  asg                  = var.asg
  dnsServers           = var.dnsServers
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  priority             = var.priority
  data_disk_sizes_gb   = [10]
  os_managed_disk_type = var.managed_disk_type
  vm_size              = var.vm_size
  license_type         = "Windows_Server"
  availability_set_id  = var.deploy ? azurerm_availability_set.availabilityset[0].id : null
  monitoringAgent      = var.monitoringAgent
  dependancyAgent      = var.dependancyAgent
  public_ip            = false
  tags                 = var.tags
}

resource "azurerm_virtual_machine_extension" "createMgmtADForest" {
  count                = var.deploy ? 1 : 0
  name                 = "createMgmtADForest"
  virtual_machine_id   = module.dc1.vm.id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.77"
  depends_on           = [module.dc1]

  settings           = <<SETTINGS
            {
                "WmfVersion": "latest",
                "configuration": {
                    "url": "https://raw.githubusercontent.com/canada-ca-terraform-modules/terraform-azurerm-active-directory/20190731.1/DSC/CreateADRootDC1.ps1.zip",
                    "script": "CreateADRootDC1.ps1",
                    "function": "CreateADRootDC1"
                },
                "configurationArguments": {
                    "DomainName": "${var.ad_domain_name}",
                    "DnsForwarder": "168.63.129.16",
                    "DnsAlternate": "${var.rootDC1IPAddress}",
                    "ReverseZoneObject": ${jsonencode(var.reverse_Zone_Object)}
                }
            }
            SETTINGS
  protected_settings = <<PROTECTED_SETTINGS
        {
            "configurationArguments": {
                "adminCreds": {
                    "UserName": "${var.admin_username}",
                    "Password": "${var.admin_password}"
                }
            }
        }
    PROTECTED_SETTINGS
}

resource "azurerm_virtual_machine_extension" "addMgmtADSecondaryDC" {
  count                = var.deploy ? 1 : 0
  name                 = "addMgmtADSecondaryDC"
  virtual_machine_id   = module.dc2.vm.id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.77"
  depends_on           = [azurerm_virtual_machine_extension.createMgmtADForest]

  settings           = <<SETTINGS
            {
                "WmfVersion": "latest",
                "configuration": {
                    "url": "https://raw.githubusercontent.com/canada-ca-terraform-modules/terraform-azurerm-active-directory/20190731.1/DSC/ConfigureADNextDC.ps1.zip",
                    "script": "ConfigureADNextDC.ps1",
                    "function": "ConfigureADNextDC"
                },
                "configurationArguments": {
                    "DomainName": "${var.ad_domain_name}",
                    "DNSServer": "${var.rootDC1IPAddress}",
                    "DnsForwarder": "${var.rootDC1IPAddress}",
                    "ReverseZoneObject": ${jsonencode(var.reverse_Zone_Object)}
                }
            }
            SETTINGS
  protected_settings = <<PROTECTED_SETTINGS
        {
            "configurationArguments": {
                "adminCreds": {
                    "UserName": "${var.admin_username}",
                    "Password": "${var.admin_password}"
                }
            }
        }
    PROTECTED_SETTINGS
}
