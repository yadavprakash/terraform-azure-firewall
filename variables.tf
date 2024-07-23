variable "name" {
  type        = string
  default     = ""
  description = "Name  (e.g. `app` or `cluster`)."
}

variable "environment" {
  type        = string
  default     = ""
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "repository" {
  type        = string
  default     = "https://github.com/yadavprakash/terraform-azure-firewall"
  description = "Terraform current module repo"
}

variable "label_order" {
  type        = list(any)
  default     = ["name", "environment"]
  description = "Label order, e.g. sequence of application name and environment `name`,`environment`,'attribute' [`webserver`,`qa`,`devops`,`public`,] ."
}

variable "managedby" {
  type        = string
  default     = ""
  description = "ManagedBy, eg 'yadavprakash'."
}

variable "enabled" {
  type        = bool
  description = "Set to false to prevent the module from creating any resources."
  default     = true
}

variable "resource_group_name" {
  type        = any
  description = "A container that holds related resources for an Azure solution"
  default     = ""
}

#Public IP

variable "public_ip_allocation_method" {
  type        = any
  description = "Defines the allocation method for this IP address. Possible values are Static or Dynamic"
  default     = "Static"
}

variable "public_ip_sku" {
  type        = any
  description = "The SKU of the Public IP. Accepted values are Basic and Standard. Defaults to Basic"
  default     = "Standard"
}

#firewall

variable "threat_intel_mode" {
  description = "(Optional) The operation mode for threat intelligence-based filtering. Possible values are: Off, Alert, Deny. Defaults to Alert."
  default     = "Alert"
  type        = string

  validation {
    condition     = contains(["Off", "Alert", "Deny"], var.threat_intel_mode)
    error_message = "The threat intel mode is invalid."
  }
}

variable "sku_tier" {
  description = "Specifies the firewall sku tier"
  default     = "Standard"
  type        = string
}

variable "sku_policy" {
  description = "Specifies the firewall-policy sku"
  default     = "Standard"
  type        = string
}

variable "sku_name" {
  type        = string
  default     = "AZFW_VNet"
  description = "(optional) describe your variable"
}

variable "subnet_id" {
  type        = string
  default     = ""
  description = "Subnet ID"
}

variable "nat_policy_collection_group" {
  type        = string
  default     = "DefaultDnatRuleCollectionGroup"
  description = "(optional) Name of nat policy group"
}

variable "net_policy_collection_group" {
  type        = string
  description = "(optional) Name of network policy group"
  default     = "DefaultNetworkRuleCollectionGroup"
}

variable "app_policy_collection_group" {
  type        = string
  default     = "DefaultApplicationRuleCollectionGroup"
  description = "(optional) Name of app policy group"

}

variable "additional_public_ips" {
  type = list(object({
    name                 = string,
    public_ip_address_id = string
  }))
  default     = []
  description = "List of additional public ips' ids to attach to the firewall."
}

variable "application_rule_collection" {
  type        = any
  default     = {}
  description = "One or more application_rule_collection blocks as defined below.."
}

variable "network_rule_collection" {
  type        = any
  default     = {}
  description = "One or more network_rule_collection blocks as defined below."
}

variable "nat_rule_collection" {
  type        = any
  default     = {}
  description = "One or more nat_rule_collection blocks as defined below."
}

variable "public_ip_names" {
  type        = list(string)
  default     = []
  description = ""
}

variable "enable_ip_subnet" {
  type        = bool
  default     = true
  description = "Should subnet id be attached to first public ip name specified in public ip names variable. To be true when there is no individual public ip."
}

variable "location" {
  type        = string
  default     = ""
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
}

variable "firewall_private_ip_ranges" {
  description = "A list of SNAT private CIDR IP ranges, or the special string `IANAPrivateRanges`, which indicates Azure Firewall does not SNAT when the destination IP address is a private range per IANA RFC 1918."
  type        = list(string)
  default     = null
}

variable "dns_servers" {
  description = "DNS Servers to use with Azure Firewall. Using this also activate DNS Proxy."
  type        = list(string)
  default     = null
}

variable "dnat-destination_ip" {
  description = "Variable to specify that you have destination ip to attach to policy or not.(Destination ip is public ip that is attached to firewall)"
  type        = bool
  default     = true
}

variable "firewall_enable" {
  type    = bool
  default = false
}

variable "identity_type" {
  description = "Specifies the type of Managed Service Identity that should be configured on this Storage Account. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned` (to enable both)."
  type        = string
  default     = "UserAssigned"
}

variable "policy_rule_enabled" {
  type        = bool
  default     = false
  description = "Flag used to control creation of policy rules."
}

variable "firewall_policy_id" {
  type        = string
  default     = null
  description = "The ID of the Firewall Policy."
}

variable "public_ip_prefix_enable" {
  type        = bool
  default     = false
  description = "Flag to control creation of public ip prefix resource."
}

variable "public_ip_prefix_sku" {
  type        = string
  default     = "Standard"
  description = "SKU for public ip prefix. Default to standard."
}

variable "public_ip_prefix_ip_version" {
  type        = string
  default     = "IPv4"
  description = "The IP Version to use, IPv6 or IPv4. Changing this forces a new resource to be created. Default is IPv4"
}

variable "prefix_public_ip_names" {
  type        = list(string)
  default     = []
  description = "Name of prefix public ips."
}

variable "prefix_public_ip_allocation_method" {
  type    = string
  default = "Static"
}

variable "prefix_public_ip_sku" {
  type    = string
  default = "Standard"
}

variable "public_ip_prefix_length" {
  type        = number
  default     = 31
  description = "Specifies the number of bits of the prefix. The value can be set between 0 (4,294,967,296 addresses) and 31 (2 addresses). Defaults to 28(16 addresses). Changing this forces a new resource to be created."
}

variable "enable_prefix_subnet" {
  type        = bool
  default     = false
  description = "Should subnet id be attached to first public ip name specified in public ip prefix name varible. To be true when there is no individual public ip."
}
