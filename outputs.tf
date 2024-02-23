output "firewall_id" {
  description = "Firewall generated id"
  value       = join("", azurerm_firewall.firewall[*].id)
}

output "firewall_name" {
  value       = join("", azurerm_firewall.firewall[*].name)
  description = "Firewall name"

}

output "private_ip_address" {
  value       = azurerm_firewall.firewall[*].ip_configuration[0].private_ip_address
  description = "Firewall private IP"

}

output "public_ip_id" {
  value = azurerm_public_ip.public_ip[*].id
}

output "public_ip_address" {
  value = azurerm_public_ip.public_ip[*].ip_address
}

output "firewall_policy_id" {
  value = join("", azurerm_firewall_policy.policy[*].id)
}

output "prefix_public_ip_id" {
  value = azurerm_public_ip.prefix_public_ip[*].id
}

output "prefix_public_ip_address" {
  value = azurerm_public_ip.prefix_public_ip[*].ip_address
}

output "public_ip_prefix_id" {
  value = join("", azurerm_public_ip_prefix.pip-prefix[*].id)
}