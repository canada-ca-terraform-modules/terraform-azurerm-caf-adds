resource azurerm_availability_set availabilityset {
  name                         = "${local.prefix}-as"
  location                     = var.location
  resource_group_name          = var.resource_group.name
  platform_fault_domain_count  = "2"
  platform_update_domain_count = "3"
  managed                      = "true"
  tags                         = var.tags
}

module "dc1" {
  source            = "github.com/canada-ca-terraform-modules/terraform-azurerm-caf-windows_virtual_machine?ref=v1.1.1"
  env               = var.env
  serverType        = "SRV"
  userDefinedString = var.userDefinedString
  postfix           = "01"
  location          = var.location
  resource_group    = var.resource_group
  subnet            = var.subnet
  nic_ip_configuration = {
    private_ip_address            = [var.rootDC1IPAddress]
    private_ip_address_allocation = ["Static"]
  }
  asg                  = var.asg
  dnsServers           = var.dnsServers
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  custom_data          = base64encode(file("${path.module}/scripts/Configure-DSC.ps1"))
  priority             = var.priority
  # data_disk_sizes_gb   = [10]
  os_managed_disk_type = var.managed_disk_type
  vm_size              = var.vm_size
  encryptDisks         = var.encryptDisks
  license_type         = "Windows_Server"
  availability_set_id  = azurerm_availability_set.availabilityset.id
  monitoringAgent      = var.monitoringAgent
  dependancyAgent      = var.dependancyAgent
  public_ip            = false
  tags                 = var.tags
}

module "dc2" {
  source            = "github.com/canada-ca-terraform-modules/terraform-azurerm-caf-windows_virtual_machine?ref=v1.1.1"
  env               = var.env
  serverType        = "SRV"
  userDefinedString = var.userDefinedString
  postfix           = "02"
  location          = var.location
  resource_group    = var.resource_group
  subnet            = var.subnet
  nic_ip_configuration = {
    private_ip_address            = [var.rootDC2IPAddress]
    private_ip_address_allocation = ["Static"]
  }
  asg                  = var.asg
  dnsServers           = var.dnsServers
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  custom_data          = base64encode(file("${path.module}/scripts/Configure-DSC.ps1"))
  priority             = var.priority
  # data_disk_sizes_gb   = [10]
  os_managed_disk_type = var.managed_disk_type
  vm_size              = var.vm_size
  encryptDisks         = var.encryptDisks
  license_type         = "Windows_Server"
  availability_set_id  = azurerm_availability_set.availabilityset.id
  monitoringAgent      = var.monitoringAgent
  dependancyAgent      = var.dependancyAgent
  public_ip            = false
  tags                 = var.tags
}

resource "azurerm_virtual_machine_extension" "createMgmtADForest" {
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
                    "url": "https://raw.githubusercontent.com/canada-ca-terraform-modules/terraform-azurerm-caf-adds/v1.1.0/DSC/CreateADRootDC1.ps1.zip",
                    "script": "CreateADRootDC1.ps1",
                    "function": "CreateADRootDC1"
                },
                "configurationArguments": {
                    "DomainName": "${var.ad_domain_name}",
                    "DnsForwarder": "168.63.129.16"
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
  name                 = "addMgmtADSecondaryDC"
  virtual_machine_id   = module.dc2.vm.id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.77"
  depends_on           = [module.dc2]
  # depends_on           = [azurerm_virtual_machine_extension.createMgmtADForest]

  settings           = <<SETTINGS
            {
                "WmfVersion": "latest",
                "configuration": {
                    "url": "https://raw.githubusercontent.com/canada-ca-terraform-modules/terraform-azurerm-caf-adds/v1.1.0/DSC/ConfigureADNextDC.ps1.zip",
                    "script": "ConfigureADNextDC.ps1",
                    "function": "ConfigureADNextDC"
                },
                "configurationArguments": {
                    "domainName": "${var.ad_domain_name}",
                    "DNSServer": "${var.rootDC1IPAddress}",
                    "DnsForwarder": "${var.rootDC1IPAddress}"
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
