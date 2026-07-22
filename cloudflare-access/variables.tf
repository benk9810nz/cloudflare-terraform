variable "cloudflare_account_id" {
  description = "Cloudflare account ID. Semaphore's terraform app injects Environment variables as `-var <key>=<value>` CLI flags using the exact key name (not real OS env vars, despite the TF_VAR_ convention) — so this must match the Semaphore environment's key exactly: cloudflare_account_id."
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token, passed the same way as cloudflare_account_id (see above). Read explicitly by the provider block in providers.tf rather than via the provider's usual CLOUDFLARE_API_TOKEN env-var auto-detection, since Semaphore doesn't set real env vars."
  type        = string
  sensitive   = true
}
