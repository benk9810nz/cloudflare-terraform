# Cloudflare Zero Trust Access + DNS + Tunnel — Terraform

Manages Cloudflare Access Applications/Policies, the main tunnel's public DNS records, and the main tunnel itself (`home-lab-v2`, cloud-managed) for `benking.co.nz`. Runs through Semaphore project "Homelab", template "Cloudflare Access — Terraform" (`app: terraform`) — a single template that shows the plan and pauses for manual Apply/Cancel confirmation in the Semaphore UI.

**Moved here 2026-07-22** from `terraform/cloudflare-access/` in the `homelab-ansible-playbooks` repo, to give Terraform its own git checkout/workspace separate from Ansible's (a `git pull` conflict in the Ansible repo previously wiped this template's persisted state via Semaphore's fallback-to-fresh-clone behavior — see the homelab's `cloudflare-access-terraform` notes for the full incident).

## Files

- `providers.tf` / `variables.tf` — Cloudflare provider config; `cloudflare_account_id`/`cloudflare_api_token` come in as Semaphore-injected Terraform variables (`-var` flags, not real env vars — see gotcha below), not the provider's usual env-var auto-detection.
- `apps.tf` / `policies.tf` — Access Applications and reusable Policies, `for_each`-over-a-locals-map pattern. `apps.tf`'s resource block appends the `agent_verification` policy (Claude Code's service token) to every app automatically via `concat(...)` — not per-app edits.
- `dns-main-tunnel.tf` — the main tunnel's public DNS CNAMEs (16 records).
- `tunnel-main.tf` — shared ingress `locals` (hostname list, host-header overrides) used by `tunnel-main-v2.tf`. The *old* local-managed tunnel's resources used to live here too; retired 2026-07-22, see git history if needed.
- `tunnel-main-v2.tf` — the live main tunnel (`home-lab-v2`, `config_src="cloudflare"`), its ingress config, and the token data source used to install it on the box.
- `tunnel-mission-control.tf` — a second, independent tunnel for work-docker (unrelated app, same pattern).

## One-time bootstrap (only relevant if state is ever lost/rebuilt)

1. **Audit live state** via the Cloudflare API (`/accounts/{id}/access/apps`, `/access/policies`, `/cfd_tunnel/{id}`, `/zones/{id}/dns_records`).
2. Make sure every `.tf` file's `locals` map matches live reality exactly — an omitted resource is a destroy on the next apply.
3. **Import everything**, one resource at a time — see each resource type's real import ID format below (they differ, verified live 2026-07-22):
   - Access Application: `terraform import 'cloudflare_zero_trust_access_application.app["key"]' "accounts/<account_id>/<app_id>"`
   - Access Policy: `terraform import 'cloudflare_zero_trust_access_policy.policy["key"]' "<account_id>/<policy_id>"` (no `accounts/` prefix — different from apps)
   - DNS record: `terraform import 'cloudflare_dns_record.main_tunnel["key"]' "<zone_id>/<record_id>"`
   - Tunnel + its config: `terraform import cloudflare_zero_trust_tunnel_cloudflared.main_v2 "<account_id>/<tunnel_id>"` / same ID for `cloudflare_zero_trust_tunnel_cloudflared_config.main_v2`
4. **Run Plan — expect zero changes.** Only once clean should Apply ever run for real.

## Regular use

Trigger the Semaphore template, read the plan carefully, confirm or reject. A plan that wants to *create* resources which already visibly exist live is the tell that state has been lost, not that the resources need creating — stop and investigate rather than confirming.

## State

Local state (`terraform.tfstate`, gitignored) lives on Semaphore's persistent workspace for this template on the Semaphore host (CTID 130) — nested at `terraform.tfstate.d/inventory.ini/terraform.tfstate` under the template's workspace dir (Semaphore's terraform app requires an inventory attached even though Terraform doesn't use one, and uses that inventory's *name* as the Terraform workspace). No remote backend configured.

## Gotchas (all discovered live, 2026-07-14 through 2026-07-22)

1. **Semaphore injects Environment values as `-var key=value` CLI flags, not real env vars.** `variables.tf`'s vars are named exactly `cloudflare_account_id`/`cloudflare_api_token` to match, and `providers.tf` sets `api_token = var.cloudflare_api_token` explicitly rather than relying on the provider's `CLOUDFLARE_API_TOKEN` auto-detection.
2. **Confirming/rejecting a `waiting_confirmation` task** isn't in Semaphore's public docs or MCP tools — the real endpoints are `POST /api/project/{project_id}/tasks/{task_id}/confirm` and `.../reject`.
3. **`config_src` is `ForceNew`** on `cloudflare_zero_trust_tunnel_cloudflared` — flipping an existing `"local"` tunnel to `"cloudflare"` destroys and recreates it (new tunnel ID), not a safe in-place update. A real migration needs a brand-new tunnel run in parallel, then a DNS cutover, then retiring the old one (see git history on `tunnel-main-v2.tf`/`tunnel-main.tf` for exactly how this was done).
4. **A `config_src="local"` tunnel's global `originRequest.caPool` doesn't surface as a top-level `config.origin_request` object** via the API — cloudflared reports it flattened onto every individual ingress rule instead, including the catch-all.
5. **Never let uncommitted/manually-copied files sit in this template's live Semaphore workspace** — a `git pull` conflict there triggers a fresh-clone fallback that can wipe the persisted state directory. Always commit + push first; verify the workspace is clean (`git status --short`) before assuming a `git pull` will fast-forward cleanly.
6. **API token permission errors show as a generic `403 Authentication error`, not a clear "missing scope" message.** Verify the token is valid first (`/user/tokens/verify`) before assuming it's revoked — if it's valid but still 403s, it's a missing permission. Editing an existing token's permissions in the dashboard has not reliably taken effect (seen twice) — creating a new token was the fix both times.
7. **Import ID formats differ per resource type** — see the bootstrap section above. Don't assume consistency across resource types in the same provider version.
