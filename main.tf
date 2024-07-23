module "labels" {
  source      = "git::https://github.com/yadavprakash/terraform-azure-labels.git?ref=v1.0.0"
  name        = var.name
  environment = var.environment
  managedby   = var.managedby
  label_order = var.label_order
  repository  = var.repository
}



resource "azurerm_public_ip" "public_ip" {
  count                = var.enabled && var.firewall_enable ? length(var.public_ip_names) : 0
  name                 = format("%s-%s-ip", module.labels.id, var.public_ip_names[count.index])
  location             = var.location
  resource_group_name  = var.resource_group_name
  allocation_method    = var.public_ip_allocation_method
  sku                  = var.public_ip_sku
  ddos_protection_mode = "VirtualNetworkInherited"
  tags                 = module.labels.tags
}


resource "azurerm_public_ip_prefix" "pip-prefix" {
  count               = var.enabled && var.firewall_enable && var.public_ip_prefix_enable ? 1 : 0
  name                = format("%s-public-ip-prefix", module.labels.id)
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.public_ip_prefix_sku
  ip_version          = var.public_ip_prefix_ip_version
  prefix_length       = var.public_ip_prefix_length
  tags                = module.labels.tags
}


resource "azurerm_public_ip" "prefix_public_ip" {
  count                = var.enabled && var.firewall_enable && var.public_ip_prefix_enable ? length(var.prefix_public_ip_names) : 0
  name                 = format("%s-%s-pip", module.labels.id, var.prefix_public_ip_names[count.index])
  location             = var.location
  resource_group_name  = var.resource_group_name
  allocation_method    = var.prefix_public_ip_allocation_method
  sku                  = var.prefix_public_ip_sku
  public_ip_prefix_id  = azurerm_public_ip_prefix.pip-prefix[0].id
  ddos_protection_mode = "VirtualNetworkInherited"
  tags                 = module.labels.tags
}



resource "azurerm_firewall" "firewall" {
  count               = var.enabled && var.firewall_enable ? 1 : 0
  name                = format("%s-firewall", module.labels.id)
  location            = var.location
  resource_group_name = var.resource_group_name
  threat_intel_mode   = var.threat_intel_mode
  sku_tier            = var.sku_tier
  sku_name            = var.sku_name
  firewall_policy_id  = join("", azurerm_firewall_policy.policy[*].id)
  tags                = module.labels.tags
  private_ip_ranges   = var.firewall_private_ip_ranges
  dns_servers         = var.dns_servers
  dynamic "ip_configuration" {
    for_each = var.public_ip_names
    iterator = it
    content {
      name = format("%s-%s-ipconfig", module.labels.id, it.value)
      # var.enable_ip_subnet will be true when individual public ip and prefix public ip both are to be deployed (none of them exist before) or only individual public ip are to be deployed.
      # var.enable_ip_subnet will be false when prefix_public_ip already exists and there are no individual public ip.
      subnet_id            = var.enable_ip_subnet ? it.key == 0 ? var.subnet_id : null : null
      public_ip_address_id = element(azurerm_public_ip.public_ip[*].id, it.key)
    }
  }

  dynamic "ip_configuration" {
    for_each = var.prefix_public_ip_names
    iterator = it
    content {
      name = format("%s-%s-pipconfig", module.labels.id, it.value)
      # var.enable_prefix_subnet will only be true when prefix public ips are to be deployed during initial apply and there are no individual public ips to be created.
      # Individual public ips can be deployed after initial apply and var.enable_ip_subnet variable must be false.
      subnet_id            = var.enable_prefix_subnet ? it.key == 0 ? var.subnet_id : null : null
      public_ip_address_id = element(azurerm_public_ip.prefix_public_ip[*].id, it.key) ##azurerm_public_ip.prefix_public_ip[*].id[it.key]
    }
  }

  dynamic "ip_configuration" {
    for_each = toset(var.additional_public_ips)

    content {
      name                 = lookup(ip_configuration.value, "name")
      public_ip_address_id = lookup(ip_configuration.value, "public_ip_address_id")
    }
  }

  lifecycle {
    ignore_changes = [
      tags,

    ]
  }
}


resource "azurerm_firewall_policy" "policy" {
  count               = var.enabled && var.firewall_enable ? 1 : 0
  name                = format("%s-firewall-FirewallPolicy", module.labels.id)
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku_policy
  dynamic "identity" {
    for_each = var.identity_type != null && var.sku_policy == "Premium" && var.sku_tier == "Premium" ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" ? [join("", azurerm_user_assigned_identity.identity[*].id)] : null
    }
  }
}


resource "azurerm_user_assigned_identity" "identity" {
  count               = var.enabled && var.firewall_enable ? 1 : 0
  location            = var.location
  name                = format("%s-fw-policy-mid", module.labels.id)
  resource_group_name = var.resource_group_name
}


resource "azurerm_firewall_policy_rule_collection_group" "app_policy_rule_collection_group" {
  count              = var.enabled && var.policy_rule_enabled ? 1 : 0
  name               = var.app_policy_collection_group
  firewall_policy_id = var.firewall_policy_id == null ? join("", azurerm_firewall_policy.policy[*].id) : var.firewall_policy_id
  priority           = 300

  dynamic "application_rule_collection" {
    for_each = var.application_rule_collection

    content {
      name     = application_rule_collection.value.name
      priority = application_rule_collection.value.priority
      action   = application_rule_collection.value.action

      dynamic "rule" {
        for_each = application_rule_collection.value.rules
        content {
          name              = lookup(rule.value, "name", null)              # string
          source_addresses  = lookup(rule.value, "source_addresses", null)  # list # currently the IP of staging rule, needs to be changed
          source_ip_groups  = lookup(rule.value, "source_ip_groups", null)  # list Specifies a list of source IP groups.
          destination_fqdns = lookup(rule.value, "destination_fqdns", null) # list of destination IP groups.
          dynamic "protocols" {
            for_each = rule.value.protocols
            content {
              port = lookup(protocols.value, "port", null)
              type = lookup(protocols.value, "type", null)
            }
          }
        }
      }
    }
  }
}


resource "azurerm_firewall_policy_rule_collection_group" "network_policy_rule_collection_group" {
  count              = var.enabled && var.policy_rule_enabled ? 1 : 0
  name               = var.net_policy_collection_group
  firewall_policy_id = var.firewall_policy_id == null ? join("", azurerm_firewall_policy.policy[*].id) : var.firewall_policy_id
  priority           = 200


  dynamic "network_rule_collection" {
    for_each = var.network_rule_collection
    content {
      name     = network_rule_collection.value.name
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        for_each = network_rule_collection.value.rules
        content {
          name                  = rule.value.name                                   # string
          protocols             = rule.value.protocols                              # list
          destination_ports     = rule.value.destination_ports                      # list - Required
          source_addresses      = lookup(rule.value, "source_addresses", null)      # list
          source_ip_groups      = lookup(rule.value, "source_ip_groups", null)      # list Specifies a list of source IP groups.
          destination_addresses = lookup(rule.value, "destination_addresses", null) # list - ["192.168.1.1", "192.168.1.2"]
          destination_ip_groups = lookup(rule.value, "destination_ip_groups", null) # list of destination IP groups.
          destination_fqdns     = lookup(rule.value, "destination_fqdns", null)     # list of destination fqdns groups.
        }
      }
    }
  }
}


resource "azurerm_firewall_policy_rule_collection_group" "nat_policy_rule_collection_group" {
  count              = var.enabled && var.dnat-destination_ip && var.policy_rule_enabled ? 1 : 0
  name               = var.nat_policy_collection_group
  firewall_policy_id = var.firewall_policy_id == null ? join("", azurerm_firewall_policy.policy[*].id) : var.firewall_policy_id
  priority           = 100

  dynamic "nat_rule_collection" {
    for_each = var.nat_rule_collection
    content {
      name     = nat_rule_collection.value.name
      priority = nat_rule_collection.value.priority
      action   = "Dnat"

      dynamic "rule" {
        for_each = nat_rule_collection.value.rules
        content {
          name                = rule.value.name                                 # string
          protocols           = rule.value.protocols                            # list
          destination_ports   = rule.value.destination_ports                    # list - Required
          source_addresses    = lookup(rule.value, "source_addresses", null)    # list
          destination_address = lookup(rule.value, "destination_address", null) # string
          translated_address  = lookup(rule.value, "translated_address", null)  # list of translated address.
          translated_port     = lookup(rule.value, "translated_port", null)     # port
        }
      }
    }
  }
}


