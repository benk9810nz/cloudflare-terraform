# New tunnel, cloud-managed from creation (config_src="cloudflare") — the
# blue-green replacement for the local-managed "home-lab" tunnel
# (tunnel-main.tf). Runs in parallel with it on CTID 199 until DNS is cut
# over (dns-main-tunnel.tf) and the old tunnel is retired. Reuses
# locals.main_tunnel_ingress / main_tunnel_ssh_ingress already declared in
# tunnel-main.tf — do not redeclare them here.
#
# Considered and rejected running this as a Docker container on
# platform-services (CTID 162) instead of a parallel systemd service on
# CTID 199: platform-services runs 1Password Connect (the credential store
# for this entire homelab), and co-locating the single most externally-
# reachable process here with it is a blast-radius regression Docker
# network segmentation alone doesn't fix. See terraform-roadmap /
# cloudflare-access-terraform memory.

resource "cloudflare_zero_trust_tunnel_cloudflared" "main_v2" {
  account_id = var.cloudflare_account_id
  name       = "home-lab-v2" # renamed to "home-lab" once the old tunnel is retired (optional cosmetic cleanup)
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "main_v2" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.main_v2.id
  config = {
    ingress = concat(
      [for r in local.main_tunnel_ingress : {
        hostname = r.hostname
        service  = "https://caddy.internal.benking.co.nz"
        origin_request = {
          http_host_header = r.http_host_header
          ca_pool          = "/etc/cloudflared/step-root-ca.crt"
        }
      }],
      [for r in local.main_tunnel_ssh_ingress : {
        hostname       = r.hostname
        service        = r.service
        origin_request = { ca_pool = "/etc/cloudflared/step-root-ca.crt" }
      }],
      [{
        service        = "http_status:404"
        origin_request = { ca_pool = "/etc/cloudflared/step-root-ca.crt" }
      }]
    )
  }
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "main_v2" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.main_v2.id
}

output "main_v2_tunnel_token" {
  value     = data.cloudflare_zero_trust_tunnel_cloudflared_token.main_v2.token
  sensitive = true
}
