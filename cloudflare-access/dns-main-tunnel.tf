# Public DNS CNAMEs for the main tunnel, previously managed by
# cloudflared-config/scripts/sync-cloudflare-dns.sh via GitHub Actions on
# every push to cloudflared-config/config.yml. Brought into Terraform
# 2026-07-21.
#
# ssh / ssh-cloudflare are SSH-only ingress rules but the old sync script
# CNAME'd them anyway (doesn't distinguish service scheme) — kept as-is here
# to match live state, not "fixed".
#
# data.cloudflare_zone.benking is already declared in tunnel-mission-control.tf.
#
# Cutover 2026-07-22: pointed at the new cloud-managed tunnel
# (home-lab-v2, tunnel-main-v2.tf) instead of the old local-managed one
# (ce2d3fc7-..., tunnel-main.tf, config_src=local, still running in
# parallel as a rollback fallback — revert this one line to roll back).

locals {
  main_tunnel_id = cloudflare_zero_trust_tunnel_cloudflared.main_v2.id

  main_tunnel_dns_names = [
    "stuff-quiz", "gym", "grocery", "wordle", "@", "admin", "app", "docs",
    "ansible", "proxmox", "job-hunter", "jira", "notepad", "sftp",
    "ssh", "ssh-cloudflare", "mcu", "money", "heater",
  ]
}

resource "cloudflare_dns_record" "main_tunnel" {
  for_each = toset(local.main_tunnel_dns_names)

  zone_id = data.cloudflare_zone.benking.zone_id
  name    = each.value
  type    = "CNAME"
  content = "${local.main_tunnel_id}.cfargotunnel.com"
  ttl     = 1
  proxied = true

  # Some records carry a stale "Managed by GitHub Actions cloudflared config
  # sync" comment (inconsistently — only 8 of 16), left over from the sync
  # script. Cosmetic, unrelated to routing — ignore rather than fight over it.
  lifecycle {
    ignore_changes = [comment]
  }
}
