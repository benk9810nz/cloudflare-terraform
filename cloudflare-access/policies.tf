# Reusable Access Policies — standalone (no application_id), attached to one
# or more apps via each app's `policies` list in apps.tf. Mirrors what's live
# today (audited 2026-07-14): almost every app shares the one "shared_access"
# policy; a handful have their own app-specific policy alongside or instead.
#
# IdP/service-token/login-method IDs referenced in `include`/`require` below
# are pre-existing objects in the Cloudflare account, not managed here.
locals {
  policies = {
    shared_access = {
      name     = "Email, Service Token & Google Access"
      decision = "allow"
      include = [
        { email = { email = "benjaminkingnz@gmail.com" } },
        { service_token = { token_id = "301f7065-e612-4d87-94f8-f882fc7ea23e" } },
        { service_token = { token_id = "18688449-b997-479b-a916-f32e0d66900e" } },
        { login_method = { id = "5247b68d-2ffb-4d4f-9feb-3e40cf1336c4" } },
        { login_method = { id = "1c256734-d5bd-4f32-bda6-dbe6d79b5ac6" } },
      ]
      session_duration = "30m"
    }

    # Dedicated jira policy — identical membership to shared_access but a long
    # session. jira.benking.co.nz (Taskboard) is a single-page app that polls in
    # the background and gets left open all day. shared_access's 30m session
    # expires mid-use, and the SPA's subsequent fetch() calls then follow a
    # cross-origin redirect to the Access login origin that fails CORS —
    # surfacing as "Failed to fetch" on save. A long session makes that rare;
    # the app also reloads itself on the redirect now. The app-level
    # session_duration ("336h" in apps.tf) is ignored while a policy sets its
    # own, so it has to live here.
    jira_access = {
      name     = "Jira Taskboard Access"
      decision = "allow"
      include = [
        { email = { email = "benjaminkingnz@gmail.com" } },
        { service_token = { token_id = "301f7065-e612-4d87-94f8-f882fc7ea23e" } },
        { service_token = { token_id = "18688449-b997-479b-a916-f32e0d66900e" } },
        { login_method = { id = "5247b68d-2ffb-4d4f-9feb-3e40cf1336c4" } },
        { login_method = { id = "1c256734-d5bd-4f32-bda6-dbe6d79b5ac6" } },
      ]
      session_duration = "336h"
    }

    bypass_everyone = {
      name     = "Bypass"
      decision = "bypass"
      include  = [{ everyone = {} }]
    }

    semaphore_ansible_runners = {
      name     = "Semaphore Ansible Runners"
      decision = "non_identity"
      include  = [{ service_token = { token_id = "4e494564-0c8e-4de4-bbbe-23719d548f05" } }]
    }

    shawn_temp = {
      name     = "Shawn Temp"
      decision = "allow"
      include = [
        { email = { email = "benjaminkingnz@gmail.com" } },
        { email = { email = "shawnchenofficial@gmail.com" } },
      ]
    }

    cloudflared_github_runner_ssh = {
      name     = "Cloudflared Github Runner SSH"
      decision = "non_identity"
      include  = [{ service_token = { token_id = "250143da-0323-41a2-a01a-a0bb5b76c318" } }]
      session_duration = "30m"
    }

    ssh_access = {
      name             = "SSH Access"
      decision         = "allow"
      include          = [{ email = { email = "benjaminkingnz@gmail.com" } }]
      require          = [{ login_method = { id = "5247b68d-2ffb-4d4f-9feb-3e40cf1336c4" } }]
      session_duration = "0s"
      mfa_config       = { mfa_disabled = true, session_duration = "" }
    }

    work_mission_control = {
      name     = "Work - Mission Control"
      decision = "allow"
      include = [
        { email = { email = "benjaminkingnz@gmail.com" } },
        { email = { email = "shaun.walters@datacom.com" } },
        { email = { email = "ben.king@datacom.com" } },
        { email = { email = "amos.norris@datacom.com" } },
        { email = { email = "robin.skidmore@datacom.com" } },
        { email = { email = "olivia.clamp@datacom.com" } },
        { email = { email = "russell.tomkinson@chorus.co.nz" } },
        { email = { email = "martin.tyson@chorus.co.nz" } },
        { email = { email = "michele.domaneschi@chorus.co.nz" } },
        { email = { email = "michele.domaneschi@gmail.com" } },
      ]
    }

    # Codified 2026-08-13: existed live since some earlier point as a
    # dashboard-only addition, never brought into Terraform until a WARP
    # route change's plan surfaced the drift (would otherwise have deleted
    # this on the next apply). Grants Datacom access to the wordle app
    # specifically, separate from sftp_access's similar Datacom-email policy.
    work_wordle = {
      name     = "Work - Wordle"
      decision = "allow"
      include = [
        { email_domain = { domain = "datacom.co.nz" } },
        { email_domain = { domain = "datacom.com" } },
      ]
    }

    sftp_access = {
      name     = "SFTP Access"
      decision = "allow"
      include = [
        { email = { email = "shaun.walters@datacom.com" } },
        { email = { email = "ben.king@datacom.com" } },
        { login_method = { id = "5247b68d-2ffb-4d4f-9feb-3e40cf1336c4" } },
      ]
    }

    # Added 2026-07-22: lets the Claude Code agent make authenticated
    # requests through Access for verification (e.g. confirming a tunnel
    # ingress host-header change actually routed to the right origin,
    # instead of only seeing the same 302 login page every unauthenticated
    # request gets). Attached to every app automatically, see apps.tf.
    agent_verification = {
      name     = "Claude Code Verification"
      decision = "non_identity"
      include  = [{ service_token = { token_id = cloudflare_zero_trust_access_service_token.agent_verification.id } }]
    }
  }
}

resource "cloudflare_zero_trust_access_service_token" "agent_verification" {
  account_id = var.cloudflare_account_id
  name       = "claude-code-verification"
  duration   = "8760h" # 1 year, then needs regenerating
}

output "agent_verification_client_id" {
  value = cloudflare_zero_trust_access_service_token.agent_verification.client_id
}

output "agent_verification_client_secret" {
  value     = cloudflare_zero_trust_access_service_token.agent_verification.client_secret
  sensitive = true
}

resource "cloudflare_zero_trust_access_policy" "policy" {
  for_each = local.policies

  account_id       = var.cloudflare_account_id
  name             = each.value.name
  decision         = each.value.decision
  include          = each.value.include
  exclude          = try(each.value.exclude, [])
  require          = try(each.value.require, [])
  session_duration = try(each.value.session_duration, null)
  mfa_config       = try(each.value.mfa_config, null)
  connection_rules = { rdp = {} }
}
