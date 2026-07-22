# New, separate Cloudflare Tunnel for work-docker (CTID 163) — distinct from
# the main tunnel in cloudflared-config/config.yml (CTID 199 → Caddy). This
# one runs cloudflared directly on work-docker so its ingress can only ever
# reach services on that box (firewall-segregated from the rest of the
# fleet, see [[work-docker-firewall-segregation]]). config_src = "cloudflare"
# means ingress rules are managed here in Terraform / the dashboard, not a
# config.yml file on the LXC — just point the container at the token below.

data "cloudflare_zone" "benking" {
  filter = { name = "benking.co.nz" }
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "mission_control" {
  account_id = var.cloudflare_account_id
  name       = "mission-control"
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "mission_control" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.mission_control.id
  config = {
    ingress = [
      {
        # jira-dashboard-ben-master's frontend container — reachable by
        # Docker DNS name since mission-control-cloudflared is joined to the
        # app's jira_net network (see /opt/work-docker/mission-control and
        # /opt/work-docker/jira-dashboard docker-compose.yml on CTID 163).
        hostname = "mission-control.benking.co.nz"
        service  = "http://jira_dashboard_frontend:80"
      },
      {
        service = "http_status:404"
      }
    ]
  }
}

resource "cloudflare_dns_record" "mission_control" {
  zone_id = data.cloudflare_zone.benking.zone_id
  name    = "mission-control"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.mission_control.id}.cfargotunnel.com"
  ttl     = 1
  proxied = true
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "mission_control" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.mission_control.id
}

output "mission_control_tunnel_token" {
  value     = data.cloudflare_zero_trust_tunnel_cloudflared_token.mission_control.token
  sensitive = true
}
