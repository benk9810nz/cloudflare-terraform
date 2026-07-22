output "app_ids" {
  description = "Map of app_key -> Cloudflare Access Application ID, for debugging and import addresses"
  value       = { for k, v in cloudflare_zero_trust_access_application.app : k => v.id }
}

output "main_tunnel_id" {
  description = "Main tunnel's Cloudflare ID, for debugging and DNS-record cross-referencing"
  value       = cloudflare_zero_trust_tunnel_cloudflared.main_v2.id
}
