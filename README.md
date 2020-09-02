# Active Directory Domain Controlers v3

## Introduction

This template will create an Active Directory forest with 1 Domain, with 2 Domain Controlers.

The template creates the following:

* Two root domain are always created.
* Choose names for the Domain, DCs, and network objects.  
* Choose the VM size.

The Domain Controllers are placed in an Availability Set to maximize uptime.

The VMs are provisioned with managed disks.  Each VM will have the AD-related management tools installed.

## Security Controls

The following security controls can be met through configuration of this template:

* TO Be Determined

## Dependancies

* [Resource Groups](https://github.com/canada-ca-azure-templates/resourcegroups/blob/master/readme.md)
* [Keyvault](https://github.com/canada-ca-azure-templates/keyvaults/blob/master/readme.md)
* [VNET-Subnet](https://github.com/canada-ca-azure-templates/vnet-subnet/blob/master/readme.md)

## Usage

```terraform
module "addsvms" {
  source              = "github.com/canada-ca-terraform-modules/terraform-azurerm-caf-adds?ref=v1.0.0"
  deploy              = true
  env                 = var.env
  userDefinedString   = "ADDS"
  resource_group      = local.resource_groups_L2.Project
  location            = local.resource_groups_L2.Project.location
  subnet              = local.subnets.MAZ
  admin_username      = var.vmConfigs.ADDS.admin_username
  admin_password      = var.vmConfigs.ADDS.admin_password
  managed_disk_type   = var.vmConfigs.ADDS.managed_disk_type
  vm_size             = var.vmConfigs.ADDS.vm_size
  rootDC1IPAddress    = local.SRV-ADDS01_IP
  rootDC2IPAddress    = local.SRV-ADDS02_IP
  ad_domain_name      = var.domain.private.name
  public_ip           = false
  asg                 = azurerm_application_security_group.AD-Servers
  tags                = var.tags
}
```

## Variables Values

| Name                    | Type   | Required | Value                                                                                                                                                                                          |
| ----------------------- | ------ | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| location                | string | no       | Azure location for resources. Default: canadacentral                                                                                                                                           |
| env                     | string | yes      | 4 chars env name                                                                                                                                                                               |
| userDefinedString       | string | yes      | User defined portion of the server name. Up to 8 chars                                                                                                                                         |
| tags                    | object | no       | Object containing a tag values - [tags pairs](#tag-object)                                                                                                                                     |
| dependancyAgent         | bool   | no       | Installs the dependancy agent for service map integration. Default: false                                                                                                                      |
| monitoringAgent         | object | no       | Configure Azure monitoring on VM. Requires configured log analytics workspace. - [monitoring agent](#monitoring-agent-object)                                                                  |
| ad_domain_name          | string | yes      | Name of the desired Active Directory domain. Example: test.local                                                                                                                               |
| public_ip               | bool   | no       | Does the VM require a public IP. true or false. Default: false                                                                                                                                 |
| dnsServers              | list   | no       | List of DNS servers IP addresses as string to use for this NIC, overrides the VNet-level dns server list - [dns servers](#dns-servers-list)                                                    |
| subnet                  | object | yes      | subnet object where the servers will be deployed to.                                                                                                                                           |
| rootDC1IPAddress        | string | yes      | Private IP assigned to the DC1 server                                                                                                                                                          |
| rootDC2IPAddress        | string | yes      | Private IP assigned to the DC2 server                                                                                                                                                          |
| resource_group          | object | yes      | Resourcegroup that will contain the VM resources                                                                                                                                               |
| admin_username          | string | yes      | Name of the VM admin account                                                                                                                                                                   |
| admin_password          | string | yes      | Password of the VM admin account                                                                                                                                                               |
| vm_size                 | string | yes      | Specifies the desired size of the Virtual Machine. Eg: Standard_F4                                                                                                                             |
| encryptDisks            | object | no       | Object containing keyvault information for disk encryption. - [encryptDisk](#encryptDisk-object)                                                                                               |
| storage_image_reference | object | no       | Specify the storage image used to create the VM. Default is 2016-Datacenter. - [storage image](#storage-image-reference-object)                                                                |
| managed_disk_type       | string | no       | Specify the type of managed storage to use for OS and Data disk. Default: "StandardSSD_LRS"                                                                                                    |
| priority                | string | no       | Specifies what should happen when the Virtual Machine is evicted for price reasons when using a Spot instance. Possible values are: Regular and Spot. Default: Regular                         |

### encryptDisk object

Example

```
encryptDisks = {
  KeyVaultResourceId = azurerm_key_vault.test-keyvault.id
  KeyVaultURL        = azurerm_key_vault.test-keyvault.vault_uri
}
```

### Tag variable

| Name     | Type   | Required | Value      |
| -------- | ------ | -------- | ---------- |
| tagname1 | string | No       | tag1 value |
| ...      | ...    | ...      | ...        |
| tagnameX | string | No       | tagX value |

## History

| Date     | Release | Change                                               |
| -------- | ------- | ---------------------------------------------------- |
| 20200805 | v1.0.2  | Update DSC to fix win2016 deployment issue           |
|          |         | Remove reverseZone since new DSC does not support it |
| 20200711 | v1.0.0  | 1st release                                          |
