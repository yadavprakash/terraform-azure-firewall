# terraform-azure-firewall
# Terraform Azure Cloud FIREWALL Module

This Terraform configuration defines an Azure infrastructure using the Azure provider.

## Table of Contents

- [Introduction](#introduction)
- [Usage](#usage)
- [Module Inputs](#module-inputs)
- [Module Outputs](#module-outputs)
- [Examples](#examples)
- [License](#license)

## Introduction
This module provides a Terraform configuration for deploying various Azure resources as part of your infrastructure. The configuration includes the deployment of resource groups, virtual networks, subnets, firewall.

## Usage
To use this module, you should have Terraform installed and configured for AZURE. This module provides the necessary Terraform configuration
for creating AZURE resources, and you can customize the inputs as needed. Below is an example of how to use this module:

# Examples

# Example: complete

```hcl
module "firewall" {
  depends_on          = [module.name_specific_subnet]
  source              = "git::https://github.com/yadavprakash/terraform-azure-firewall.git?ref=v1.0.0"
  name                = local.name
  environment         = local.environment
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  subnet_id           = module.name_specific_subnet.specific_subnet_id
  public_ip_names     = ["ingress", "vnet"] // Name of public ips you want to create.
  firewall_enable     = true
  policy_rule_enabled = true
  application_rule_collection = [
    {
      name     = "example_app_policy"
      priority = 200
      action   = "Allow"
      rules = [
        {
          name              = "app_test"
          source_addresses  = ["*"] // ["X.X.X.X"]
          destination_fqdns = ["*"] // ["X.X.X.X"]
          protocols = [
            {
              port = "443"
              type = "Https"
            },
            {
              port = "80"
              type = "Http"
            }
          ]
        }
      ]
    }
  ]

  network_rule_collection = [
    {
      name     = "example_network_policy"
      priority = "100"
      action   = "Allow"
      rules = [
        {
          name                  = "ssh"
          protocols             = ["TCP"]
          source_addresses      = ["*"] // ["X.X.X.X"]
          destination_addresses = ["*"] // ["X.X.X.X"]
          destination_ports     = ["22"]
        }

      ]
    },
    {
      name     = "example_network_policy-2"
      priority = "101"
      action   = "Allow"
      rules = [
        {
          name                  = "smtp"
          protocols             = ["TCP"]
          source_addresses      = ["*"] // ["X.X.X.X"]
          destination_addresses = ["*"] // ["X.X.X.X"]
          destination_ports     = ["587"]
        }
      ]
    }
  ]

  nat_rule_collection = [
    {
      name     = "example_nat_policy-1"
      priority = "101"
      rules = [
        {
          name                = "http"
          protocols           = ["TCP"]
          source_addresses    = ["*"] // ["X.X.X.X"]
          destination_ports   = ["80"]
          source_addresses    = ["*"]
          translated_port     = "80"
          translated_address  = "10.1.1.1"                           #provide private ip address to translate
          destination_address = module.firewall.public_ip_address[1] //Public ip associated with firewall. Here index 1 indicates 'vnet ip' (from public_ip_names     = ["ingress" , "vnet"])

        },
        {
          name                = "https"
          protocols           = ["TCP"]
          destination_ports   = ["443"]
          source_addresses    = ["*"]
          translated_port     = "443"
          translated_address  = "10.1.1.1"                           #provide private ip address to translate
          destination_address = module.firewall.public_ip_address[1] //Public ip associated with firewall

        }
      ]
    },

    {
      name     = "example-nat-policy-2"
      priority = "100"
      rules = [
        {
          name                = "http"
          protocols           = ["TCP"]
          source_addresses    = ["*"] // ["X.X.X.X"]
          destination_ports   = ["80"]
          translated_port     = "80"
          translated_address  = "10.1.1.2"                           #provide private ip address to translate
          destination_address = module.firewall.public_ip_address[0] //Public ip associated with firewall.Here index 0 indicates 'ingress ip' (from public_ip_names     = ["ingress" , "vnet"])

        },
        {
          name                = "https"
          protocols           = ["TCP"]
          source_addresses    = ["*"] // ["X.X.X.X"]
          destination_ports   = ["443"]
          translated_port     = "443"
          translated_address  = "10.1.1.2"
          destination_address = module.firewall.public_ip_address[0]
        }
      ]
    }
  ]
}
```

# Example: firewall-with-isolated-rules

```hcl
module "firewall-rules" {
  depends_on          = [module.firewall]
  source              = "git::https://github.com/yadavprakash/terraform-azure-firewall.git?ref=v1.0.0"
  name                = local.name
  environment         = local.environment
  policy_rule_enabled = true
  firewall_policy_id  = module.firewall.firewall_policy_id
  application_rule_collection = [
    {
      name     = "example_app_policy"
      priority = 200
      action   = "Allow"
      rules = [
        {
          name              = "app_test"
          source_addresses  = ["*"] // ["X.X.X.X"]
          destination_fqdns = ["*"] // ["X.X.X.X"]
          protocols = [
            {
              port = "443"
              type = "Https"
            },
            {
              port = "80"
              type = "Http"
            }
          ]
        }
      ]
    }
  ]
  network_rule_collection = [
    {
      name     = "example_network_policy"
      priority = "100"
      action   = "Allow"
      rules = [
        {
          name                  = "ssh"
          protocols             = ["TCP"]
          source_addresses      = ["*"] // ["X.X.X.X"]
          destination_addresses = ["*"] // ["X.X.X.X"]
          destination_ports     = ["22"]
        }

      ]
    },
    {
      name     = "example_network_policy-2"
      priority = "101"
      action   = "Allow"
      rules = [
        {
          name                  = "smtp"
          protocols             = ["TCP"]
          source_addresses      = ["*"] // ["X.X.X.X"]
          destination_addresses = ["*"] // ["X.X.X.X"]
          destination_ports     = ["587"]
        }
      ]
    }
  ]

  nat_rule_collection = [
    {
      name     = "example_nat_policy-1"
      priority = "101"
      rules = [
        {
          name                = "http"
          protocols           = ["TCP"]
          source_addresses    = ["*"] // ["X.X.X.X"]
          destination_ports   = ["80"]
          source_addresses    = ["*"]
          translated_port     = "80"
          translated_address  = "10.1.1.1"                           #provide private ip address to translate
          destination_address = module.firewall.public_ip_address[1] //Public ip associated with firewall. Here index 1 indicates 'vnet ip' (from public_ip_names     = ["ingress" , "vnet"])

        },
        {
          name                = "https"
          protocols           = ["TCP"]
          destination_ports   = ["443"]
          source_addresses    = ["*"]
          translated_port     = "443"
          translated_address  = "10.1.1.1"                           #provide private ip address to translate
          destination_address = module.firewall.public_ip_address[1] //Public ip associated with firewall

        }
      ]
    },
    {
      name     = "example-nat-policy-2"
      priority = "100"
      rules = [
        {
          name                = "http"
          protocols           = ["TCP"]
          source_addresses    = ["*"] // ["X.X.X.X"]
          destination_ports   = ["80"]
          translated_port     = "80"
          translated_address  = "10.1.1.2"                           #provide private ip address to translate
          destination_address = module.firewall.public_ip_address[0] //Public ip associated with firewall.Here index 0 indicates 'ingress ip' (from public_ip_names     = ["ingress" , "vnet"])

        },
        {
          name                = "https"
          protocols           = ["TCP"]
          source_addresses    = ["*"] // ["X.X.X.X"]
          destination_ports   = ["443"]
          translated_port     = "443"
          translated_address  = "10.1.1.2"                           #provide private ip address to translate
          destination_address = module.firewall.public_ip_address[0] //Public ip associated with firewall
        }
      ]
    }
  ]
}

```
# Example: firewall-with-public-ip-prefix

```hcl
module "firewall" {
  depends_on              = [module.name_specific_subnet]
  source                  = "git::https://github.com/yadavprakash/terraform-azure-firewall.git?ref=v1.0.0"
  name                    = local.name
  environment             = local.environment
  resource_group_name     = module.resource_group.resource_group_name
  location                = module.resource_group.resource_group_location
  subnet_id               = module.name_specific_subnet.specific_subnet_id
  public_ip_prefix_enable = true
  prefix_public_ip_names  = ["test-1", "test-2"]
  public_ip_prefix_length = 31
  enable_prefix_subnet    = true
  firewall_enable     = true
  policy_rule_enabled = true
  application_rule_collection = [
    {
      name     = "example_app_policy"
      priority = 200
      action   = "Allow"
      rules = [
        {
          name              = "app_test"
          source_addresses  = ["*"] // ["X.X.X.X"]
          destination_fqdns = ["*"] // ["X.X.X.X"]
          protocols = [
            {
              port = "443"
              type = "Https"
            },
            {
              port = "80"
              type = "Http"
            }
          ]
        }
      ]
    }
  ]

  network_rule_collection = [
    {
      name     = "example_network_policy"
      priority = "100"
      action   = "Allow"
      rules = [
        {
          name                  = "ssh"
          protocols             = ["TCP"]
          source_addresses      = ["*"] // ["X.X.X.X"]
          destination_addresses = ["*"] // ["X.X.X.X"]
          destination_ports     = ["22"]
        }

      ]
    },
    {
      name     = "example_network_policy-2"
      priority = "101"
      action   = "Allow"
      rules = [
        {
          name                  = "smtp"
          protocols             = ["TCP"]
          source_addresses      = ["*"] // ["X.X.X.X"]
          destination_addresses = ["*"] // ["X.X.X.X"]
          destination_ports     = ["587"]
        }
      ]
    }
  ]

  nat_rule_collection = [
    {
      name     = "example_nat_policy-1"
      priority = "101"
      rules = [
        {
          name                = "http"
          protocols           = ["TCP"]
          source_addresses    = ["*"] // ["X.X.X.X"]
          destination_ports   = ["80"]
          source_addresses    = ["*"]
          translated_port     = "80"
          translated_address  = "10.1.1.1"                                  #provide private ip address to translate
          destination_address = module.firewall.prefix_public_ip_address[1] //Public ip associated with firewall. Here index 1 indicates 'vnet ip' (from public_ip_names     = ["ingress" , "vnet"])

        },
        {
          name                = "https"
          protocols           = ["TCP"]
          destination_ports   = ["443"]
          source_addresses    = ["*"]
          translated_port     = "443"
          translated_address  = "10.1.1.1"                                  #provide private ip address to translate
          destination_address = module.firewall.prefix_public_ip_address[1] //Public ip associated with firewall

        }
      ]
    },

    {
      name     = "example-nat-policy-2"
      priority = "100"
      rules = [
        {
          name                = "http"
          protocols           = ["TCP"]
          source_addresses    = ["*"] // ["X.X.X.X"]
          destination_ports   = ["80"]
          translated_port     = "80"
          translated_address  = "10.1.1.2"                                  #provide private ip address to translate
          destination_address = module.firewall.prefix_public_ip_address[0] //Public ip associated with firewall.Here index 0 indicates 'ingress ip' (from public_ip_names     = ["ingress" , "vnet"])

        },
        {
          name                = "https"
          protocols           = ["TCP"]
          source_addresses    = ["*"] // ["X.X.X.X"]
          destination_ports   = ["443"]
          translated_port     = "443"
          translated_address  = "10.1.1.2"                                  #provide private ip address to translate
          destination_address = module.firewall.prefix_public_ip_address[0] //Public ip associated with firewall
        }
      ]
    }
  ]
}
```

This example demonstrates how to create various AZURE resources using the provided modules. Adjust the input values to suit your specific requirements.

## Examples
For detailed examples on how to use this module, please refer to the [examples](https://github.com/yadavprakash/terraform-azure-firewall/blob/master/_example) directory within this repository.

## License
This Terraform module is provided under the **MIT** License. Please see the [LICENSE](https://github.com/yadavprakash/terraform-azure-firewall/blob/master/LICENSE) file for more details.

## Author
Your Name
Replace **MIT** and **yadavprakash** with the appropriate license and your information. Feel free to expand this README with additional details or usage instructions as needed for your specific use case.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >=2.90.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >=2.90.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_labels"></a> [labels](#module\_labels) | git::https://github.com/yadavprakash/terraform-azure-labels.git | v1.0.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_firewall.firewall](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall) | resource |
| [azurerm_firewall_policy.policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy) | resource |
| [azurerm_firewall_policy_rule_collection_group.app_policy_rule_collection_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy_rule_collection_group) | resource |
| [azurerm_firewall_policy_rule_collection_group.nat_policy_rule_collection_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy_rule_collection_group) | resource |
| [azurerm_firewall_policy_rule_collection_group.network_policy_rule_collection_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy_rule_collection_group) | resource |
| [azurerm_public_ip.prefix_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip_prefix.pip-prefix](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip_prefix) | resource |
| [azurerm_user_assigned_identity.identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_public_ips"></a> [additional\_public\_ips](#input\_additional\_public\_ips) | List of additional public ips' ids to attach to the firewall. | <pre>list(object({<br>    name                 = string,<br>    public_ip_address_id = string<br>  }))</pre> | `[]` | no |
| <a name="input_app_policy_collection_group"></a> [app\_policy\_collection\_group](#input\_app\_policy\_collection\_group) | (optional) Name of app policy group | `string` | `"DefaultApplicationRuleCollectionGroup"` | no |
| <a name="input_application_rule_collection"></a> [application\_rule\_collection](#input\_application\_rule\_collection) | One or more application\_rule\_collection blocks as defined below.. | `any` | `{}` | no |
| <a name="input_dnat-destination_ip"></a> [dnat-destination\_ip](#input\_dnat-destination\_ip) | Variable to specify that you have destination ip to attach to policy or not.(Destination ip is public ip that is attached to firewall) | `bool` | `true` | no |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | DNS Servers to use with Azure Firewall. Using this also activate DNS Proxy. | `list(string)` | `null` | no |
| <a name="input_enable_ip_subnet"></a> [enable\_ip\_subnet](#input\_enable\_ip\_subnet) | Should subnet id be attached to first public ip name specified in public ip names variable. To be true when there is no individual public ip. | `bool` | `true` | no |
| <a name="input_enable_prefix_subnet"></a> [enable\_prefix\_subnet](#input\_enable\_prefix\_subnet) | Should subnet id be attached to first public ip name specified in public ip prefix name varible. To be true when there is no individual public ip. | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources. | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment (e.g. `prod`, `dev`, `staging`). | `string` | `""` | no |
| <a name="input_firewall_enable"></a> [firewall\_enable](#input\_firewall\_enable) | n/a | `bool` | `false` | no |
| <a name="input_firewall_policy_id"></a> [firewall\_policy\_id](#input\_firewall\_policy\_id) | The ID of the Firewall Policy. | `string` | `null` | no |
| <a name="input_firewall_private_ip_ranges"></a> [firewall\_private\_ip\_ranges](#input\_firewall\_private\_ip\_ranges) | A list of SNAT private CIDR IP ranges, or the special string `IANAPrivateRanges`, which indicates Azure Firewall does not SNAT when the destination IP address is a private range per IANA RFC 1918. | `list(string)` | `null` | no |
| <a name="input_identity_type"></a> [identity\_type](#input\_identity\_type) | Specifies the type of Managed Service Identity that should be configured on this Storage Account. Possible values are `SystemAssigned`, `UserAssigned`, `SystemAssigned, UserAssigned` (to enable both). | `string` | `"UserAssigned"` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | Label order, e.g. sequence of application name and environment `name`,`environment`,'attribute' [`webserver`,`qa`,`devops`,`public`,] . | `list(any)` | <pre>[<br>  "name",<br>  "environment"<br>]</pre> | no |
| <a name="input_location"></a> [location](#input\_location) | The location/region where the virtual network is created. Changing this forces a new resource to be created. | `string` | `""` | no |
| <a name="input_managedby"></a> [managedby](#input\_managedby) | ManagedBy, eg 'yadavprakash'. | `string` | `""` | no |
| <a name="input_name"></a> [name](#input\_name) | Name  (e.g. `app` or `cluster`). | `string` | `""` | no |
| <a name="input_nat_policy_collection_group"></a> [nat\_policy\_collection\_group](#input\_nat\_policy\_collection\_group) | (optional) Name of nat policy group | `string` | `"DefaultDnatRuleCollectionGroup"` | no |
| <a name="input_nat_rule_collection"></a> [nat\_rule\_collection](#input\_nat\_rule\_collection) | One or more nat\_rule\_collection blocks as defined below. | `any` | `{}` | no |
| <a name="input_net_policy_collection_group"></a> [net\_policy\_collection\_group](#input\_net\_policy\_collection\_group) | (optional) Name of network policy group | `string` | `"DefaultNetworkRuleCollectionGroup"` | no |
| <a name="input_network_rule_collection"></a> [network\_rule\_collection](#input\_network\_rule\_collection) | One or more network\_rule\_collection blocks as defined below. | `any` | `{}` | no |
| <a name="input_policy_rule_enabled"></a> [policy\_rule\_enabled](#input\_policy\_rule\_enabled) | Flag used to control creation of policy rules. | `bool` | `false` | no |
| <a name="input_prefix_public_ip_allocation_method"></a> [prefix\_public\_ip\_allocation\_method](#input\_prefix\_public\_ip\_allocation\_method) | n/a | `string` | `"Static"` | no |
| <a name="input_prefix_public_ip_names"></a> [prefix\_public\_ip\_names](#input\_prefix\_public\_ip\_names) | Name of prefix public ips. | `list(string)` | `[]` | no |
| <a name="input_prefix_public_ip_sku"></a> [prefix\_public\_ip\_sku](#input\_prefix\_public\_ip\_sku) | n/a | `string` | `"Standard"` | no |
| <a name="input_public_ip_allocation_method"></a> [public\_ip\_allocation\_method](#input\_public\_ip\_allocation\_method) | Defines the allocation method for this IP address. Possible values are Static or Dynamic | `any` | `"Static"` | no |
| <a name="input_public_ip_names"></a> [public\_ip\_names](#input\_public\_ip\_names) | n/a | `list(string)` | `[]` | no |
| <a name="input_public_ip_prefix_enable"></a> [public\_ip\_prefix\_enable](#input\_public\_ip\_prefix\_enable) | Flag to control creation of public ip prefix resource. | `bool` | `false` | no |
| <a name="input_public_ip_prefix_ip_version"></a> [public\_ip\_prefix\_ip\_version](#input\_public\_ip\_prefix\_ip\_version) | The IP Version to use, IPv6 or IPv4. Changing this forces a new resource to be created. Default is IPv4 | `string` | `"IPv4"` | no |
| <a name="input_public_ip_prefix_length"></a> [public\_ip\_prefix\_length](#input\_public\_ip\_prefix\_length) | Specifies the number of bits of the prefix. The value can be set between 0 (4,294,967,296 addresses) and 31 (2 addresses). Defaults to 28(16 addresses). Changing this forces a new resource to be created. | `number` | `31` | no |
| <a name="input_public_ip_prefix_sku"></a> [public\_ip\_prefix\_sku](#input\_public\_ip\_prefix\_sku) | SKU for public ip prefix. Default to standard. | `string` | `"Standard"` | no |
| <a name="input_public_ip_sku"></a> [public\_ip\_sku](#input\_public\_ip\_sku) | The SKU of the Public IP. Accepted values are Basic and Standard. Defaults to Basic | `any` | `"Standard"` | no |
| <a name="input_repository"></a> [repository](#input\_repository) | Terraform current module repo | `string` | `"https://github.com/yadavprakash/terraform-azure-firewall"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | A container that holds related resources for an Azure solution | `any` | `""` | no |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | (optional) describe your variable | `string` | `"AZFW_VNet"` | no |
| <a name="input_sku_policy"></a> [sku\_policy](#input\_sku\_policy) | Specifies the firewall-policy sku | `string` | `"Standard"` | no |
| <a name="input_sku_tier"></a> [sku\_tier](#input\_sku\_tier) | Specifies the firewall sku tier | `string` | `"Standard"` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID | `string` | `""` | no |
| <a name="input_threat_intel_mode"></a> [threat\_intel\_mode](#input\_threat\_intel\_mode) | (Optional) The operation mode for threat intelligence-based filtering. Possible values are: Off, Alert, Deny. Defaults to Alert. | `string` | `"Alert"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_firewall_id"></a> [firewall\_id](#output\_firewall\_id) | Firewall generated id |
| <a name="output_firewall_name"></a> [firewall\_name](#output\_firewall\_name) | Firewall name |
| <a name="output_firewall_policy_id"></a> [firewall\_policy\_id](#output\_firewall\_policy\_id) | n/a |
| <a name="output_prefix_public_ip_address"></a> [prefix\_public\_ip\_address](#output\_prefix\_public\_ip\_address) | n/a |
| <a name="output_prefix_public_ip_id"></a> [prefix\_public\_ip\_id](#output\_prefix\_public\_ip\_id) | n/a |
| <a name="output_private_ip_address"></a> [private\_ip\_address](#output\_private\_ip\_address) | Firewall private IP |
| <a name="output_public_ip_address"></a> [public\_ip\_address](#output\_public\_ip\_address) | n/a |
| <a name="output_public_ip_id"></a> [public\_ip\_id](#output\_public\_ip\_id) | n/a |
| <a name="output_public_ip_prefix_id"></a> [public\_ip\_prefix\_id](#output\_public\_ip\_prefix\_id) | n/a |
<!-- END_TF_DOCS -->