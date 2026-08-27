# Desired-state config for Cloudflare Zero Trust Access Applications.
# Mirrors live state as audited 2026-07-14 (13 apps) — see README.md for the
# import procedure. Every hostname currently gated by Access must have an
# entry here before the first real `terraform apply`, or it gets destroyed.
locals {
  desired_apps = {
    job_hunter = {
      name                 = "job-hunter"
      domain               = "job-hunter.benking.co.nz"
      session_duration     = "24h"
      app_launcher_visible = true
      policy_refs          = [{ key = "shared_access", precedence = 1 }]
    }
    jira = {
      name                 = "jira"
      domain               = "jira.benking.co.nz"
      session_duration     = "336h"
      app_launcher_visible = true
      # Own policy (not shared_access) so the session is 336h, not 30m — the
      # Taskboard SPA is left open all day and shared_access's short session
      # broke background fetches. See policies.tf jira_access.
      policy_refs          = [{ key = "jira_access", precedence = 1 }]
    }
    gym_health_sync = {
      name                 = "gym app"
      domain               = "gym.benking.co.nz/api/health/steps/sync"
      session_duration     = "24h"
      app_launcher_visible = true
      policy_refs          = [{ key = "bypass_everyone", precedence = 1 }]
    }
    browser = {
      name                 = "browser"
      domain               = "browser.benking.co.nz"
      session_duration     = "24h"
      app_launcher_visible = true
      policy_refs          = [{ key = "shared_access", precedence = 1 }]
    }
    ansible = {
      name                 = "ansible"
      domain               = "ansible.benking.co.nz"
      session_duration     = "24h"
      app_launcher_visible = true
      policy_refs = [
        { key = "semaphore_ansible_runners", precedence = 1 },
        { key = "shared_access", precedence = 2 },
      ]
    }
    proxmox = {
      name                 = "Proxmox (Demo)"
      domain               = "proxmox.benking.co.nz"
      session_duration     = "24h"
      app_launcher_visible = true
      policy_refs          = [{ key = "shared_access", precedence = 1 }]
    }
    gym = {
      name                 = "Gym"
      domain               = "gym.benking.co.nz"
      session_duration     = "24h"
      app_launcher_visible = true
      policy_refs = [
        { key = "shared_access", precedence = 1 },
        { key = "shawn_temp", precedence = 2 },
      ]
    }
    docs = {
      name                 = "app"
      domain               = "docs.benking.co.nz"
      session_duration     = "24h"
      app_launcher_visible = true
      policy_refs          = [{ key = "shared_access", precedence = 1 }]
    }
    # session_duration + work_wordle policy codified 2026-08-13 to match
    # live state (see policies.tf's work_wordle comment) — was drift, not
    # an intentional divergence, but matched here rather than reverted.
    wordle = {
      name                 = "wordle"
      domain               = "wordle.benking.co.nz"
      session_duration     = "336h"
      app_launcher_visible = true
      policy_refs = [
        { key = "shared_access", precedence = 1 },
        { key = "work_wordle", precedence = 3 },
      ]
    }
    grocery = {
      name                 = "grocery"
      domain               = "grocery.benking.co.nz"
      session_duration     = "24h"
      app_launcher_visible = true
      policy_refs          = [{ key = "shared_access", precedence = 1 }]
    }
    stuff_quiz = {
      name                 = "stuff-quiz"
      domain               = "stuff-quiz.benking.co.nz"
      session_duration     = "24h"
      app_launcher_visible = true
      policy_refs          = [{ key = "shared_access", precedence = 1 }]
    }
    ssh_cloudflare = {
      name                 = "SSH Clouflare Github Runner"
      domain               = "ssh-cloudflare.benking.co.nz"
      session_duration     = "24h"
      app_launcher_visible = true
      policy_refs          = [{ key = "cloudflared_github_runner_ssh", precedence = 1 }]
    }
    admin = {
      name                 = "admin"
      domain               = "admin.benking.co.nz"
      extra_domains        = ["ssh.benking.co.nz"]
      session_duration     = "24h"
      app_launcher_visible = true
      policy_refs          = [{ key = "ssh_access", precedence = 1 }]
    }

    # Added 2026-07-14: notepad, kanban, and the root domain were tunneled
    # (cloudflared-config/config.yml) and had live Caddy routes but no
    # Access app at all — anyone could reach them unauthenticated.
    # kanban (focalboard) decommissioned 2026-07-21 — see [[focalboard]] memory.
    notepad = {
      name                 = "notepad"
      domain               = "notepad.benking.co.nz"
      session_duration     = "24h"
      app_launcher_visible = true
      policy_refs          = [{ key = "shared_access", precedence = 1 }]
    }
    root = {
      name                 = "benking.co.nz"
      domain               = "benking.co.nz"
      session_duration     = "24h"
      app_launcher_visible = true
      policy_refs          = [{ key = "shared_access", precedence = 1 }]
    }

    # Added 2026-07-16: work-docker (CTID 163) sandbox tunnel, see
    # tunnel-mission-control.tf. Access-protected, single-user policy.
    mission_control = {
      name                 = "Mission Control"
      domain               = "mission-control.benking.co.nz"
      session_duration     = "24h"
      app_launcher_visible = true
      policy_refs          = [{ key = "work_mission_control", precedence = 1 }]
    }

    # Added 2026-07-20: sftp.benking.co.nz (CTID 121) newly tunneled, gated
    # to a dedicated policy for the two Datacom accounts rather than the
    # shared_access/ssh_access policies used elsewhere.
    sftp = {
      name                 = "SFTP"
      domain               = "sftp.benking.co.nz"
      session_duration     = "24h"
      app_launcher_visible = true
      policy_refs          = [{ key = "sftp_access", precedence = 1 }]
    }
  }
}

resource "cloudflare_zero_trust_access_application" "app" {
  for_each = local.desired_apps

  account_id = var.cloudflare_account_id
  name       = each.value.name
  destinations = [
    for d in concat([each.value.domain], try(each.value.extra_domains, [])) :
    { type = "public", uri = d }
  ]
  type                 = "self_hosted"
  session_duration     = each.value.session_duration
  app_launcher_visible = each.value.app_launcher_visible

  # Matches current live defaults for every app (audited 2026-07-14) — set
  # explicitly so Terraform doesn't silently flip them via provider defaults.
  auto_redirect_to_identity  = false
  enable_binding_cookie      = false
  http_only_cookie_attribute = false
  options_preflight_bypass   = false

  # Appends the agent_verification policy (policies.tf) to every app
  # uniformly, added 2026-07-22 — rather than editing each app's
  # policy_refs list individually, since it's meant to apply everywhere,
  # including apps added in the future.
  policies = concat(
    [
      for p in each.value.policy_refs : {
        id         = cloudflare_zero_trust_access_policy.policy[p.key].id
        precedence = p.precedence
      }
    ],
    [{
      id         = cloudflare_zero_trust_access_policy.policy["agent_verification"].id
      precedence = 99
    }]
  )
}
