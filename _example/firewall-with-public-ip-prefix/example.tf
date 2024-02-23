provider "azurerm" {
  features {}
}

locals {
  name        = "app578"
  environment = "test"
}


module "resource_group" {
  source      = "git::https://github.com/opsstation/terraform-azure-resource-group.git?ref=v1.0.0"
  name        = "app21"
  environment = "tested"
  location    = "North Europe"
}


module "vnet" {
  source              = "git::https://github.com/opsstation/terraform-azure-vnet.git?ref=v1.0.0"
  name                = "app"
  environment         = "test"
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  address_spaces      = ["10.0.0.0/16"]
}


module "name_specific_subnet" {
  source = "git::https://github.com/opsstation/terraform-azure-subnet.git?ref=v1.0.1"

  name                 = local.name
  environment          = local.environment
  resource_group_name  = module.resource_group.resource_group_name
  location             = module.resource_group.resource_group_location
  virtual_network_name = join("", module.vnet[*].vnet_name)

  #subnet
  specific_name_subnet  = true
  specific_subnet_names = "AzureFirewallSubnet"
  subnet_prefixes       = ["10.0.1.0/24"]
  # route_table
  routes = [
    {
      name           = "rt-test"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
    }
  ]
}


module "firewall" {
  depends_on              = [module.name_specific_subnet]
  source                  = "../.."
  name                    = local.name
  environment             = local.environment
  resource_group_name     = module.resource_group.resource_group_name
  location                = module.resource_group.resource_group_location
  subnet_id               = module.name_specific_subnet.specific_subnet_id[0]
  public_ip_prefix_enable = true
  prefix_public_ip_names  = ["test-1", "test-2"]
  public_ip_prefix_length = 31
  enable_prefix_subnet    = true
  firewall_enable         = true
  policy_rule_enabled     = true
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
