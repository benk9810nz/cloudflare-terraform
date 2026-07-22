terraform {
  required_version = ">= 1.5.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

# api_token passed explicitly via var.cloudflare_api_token (see variables.tf)
# rather than relying on a real CLOUDFLARE_API_TOKEN env var, since Semaphore's
# terraform app injects Environment values as -var flags, not OS env vars.
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
