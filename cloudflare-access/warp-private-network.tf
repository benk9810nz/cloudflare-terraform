# Routes the whole homelab subnet through the main tunnel (tunnel-main-v2.tf)
# for any device enrolled in Cloudflare WARP against this Zero Trust org —
# full-subnet access from outside the LAN, without opening an inbound port
# on the home router. Additive to the existing HTTP ingress in
# tunnel-main-v2.tf; Caddy/tunnel-main-v2.tf's hostname routing is unchanged.
#
# WARP client enrollment itself (installing the app, logging in) is a
# per-device manual step, not something Terraform manages.

resource "cloudflare_zero_trust_tunnel_cloudflared_route" "homelab_subnet" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.main_v2.id
  network    = "10.233.76.0/22"
  comment    = "Homelab LXC subnet (Proxmox, apps, infra) — WARP private network route"
}

# Device-side split DNS: WARP clients send lookups for these two suffixes
# straight to Technitium (10.233.76.11) over the private route above instead
# of Cloudflare's own resolver, so *.internal / *.lan hostnames resolve the
# same way for an outside WARP client as they do on the LAN. This is a
# singleton "default profile" resource — it replaces the account's entire
# local-domain-fallback list on apply, so any future addition belongs here,
# not in a separate resource.
resource "cloudflare_zero_trust_device_default_profile_local_domain_fallback" "homelab" {
  account_id = var.cloudflare_account_id
  domains = [
    {
      suffix      = "internal.benking.co.nz"
      description = "Homelab apps/infra via Caddy (Step-CA TLS)"
      dns_server  = ["10.233.76.11"]
    },
    {
      suffix      = "lan.benking.co.nz"
      description = "Homelab raw LXC IPs"
      dns_server  = ["10.233.76.11"]
    },
  ]
}
