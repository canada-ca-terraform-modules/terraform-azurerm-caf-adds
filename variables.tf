variable "location" {
  description = "Location of the network"
  default     = "canadacentral"
}

variable "tags" {
  default = {
  }
}

variable "env" {
  description = "4 chars env name"
  type        = string
}

variable "serverType" {
  description = "3 chars server type"
  type        = string
  default     = "SRV"
}

variable "userDefinedString" {
  description = "User defined portion of the server name. Up to 8 chars minus the postfix lenght"
  type        = string
  default     = "ADDS"
}

variable "deploy" {
  description = "Should resources in this module be deployed"
  default     = true
}

variable "monitoringAgent" {
  description = "Should the VM be monitored"
  default     = null
}

variable "dependancyAgent" {
  description = "Should the VM be include the dependancy agent"
  default     = null
}

variable "ad_domain_name" {
  default = "module.local"
}

variable "reverse_Zone_Object" {
  default = ["2.250.10"]
}

variable "public_ip" {
  description = "Should the VM be assigned public IP(s). True or false."
  default     = false
}

variable "dnsServers" {
  default = ["168.63.129.16"]
}

variable "subnet" {
  description = "subnet object to which the VM NIC will connect to"
}

variable "asg" {
  description = "ASG resource to join the NIC to"
  default     = null
}

variable "rootDC1IPAddress" {}

variable "rootDC2IPAddress" {}

variable "rootDC2IPAddress_allocation" {
  default = "Static"
}

variable "resource_group" {
  default = ""
}

variable "admin_username" {
  default = "azureadmin"
}

variable "admin_password" {
  default = ""
}

variable "vm_size" {
  default = "Standard_B2ms"
}

variable "storage_image_reference" {
  default = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

variable "managed_disk_type" {
  default = "StandardSSD_LRS"
}

variable "priority" {
  default = "Regular"
}