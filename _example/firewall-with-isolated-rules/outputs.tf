output "firewall_id" {
  description = "Firewall generated id"
  value       = module.firewall.firewall_id
}

output "firewall_name" {
  value       = module.firewall.firewall_name
  description = "Firewall name"

}

output "firewall-private_ip_address" {
  value       = module.firewall.private_ip_address
  description = "Firewall private IP"

}

output "public_ip_id" {
  value = module.firewall.public_ip_id
}

output "public_ip_address" {
  value = module.firewall.public_ip_address
}
