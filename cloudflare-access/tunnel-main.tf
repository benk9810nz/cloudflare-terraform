# Shared ingress locals for the main tunnel — used by tunnel-main-v2.tf
# (the live cloud-managed tunnel, "home-lab-v2") and previously also by the
# old local-managed tunnel ("home-lab", config_src=local) that lived in
# this file until its retirement 2026-07-22, once the blue-green migration
# to tunnel-main-v2.tf was confirmed stable. See tunnel-main-v2.tf and
# README.md "Main tunnel DNS + ingress" for the migration history.

locals {
  main_tunnel_ingress = [
    { hostname = "stuff-quiz.benking.co.nz", http_host_header = "stuff-quiz.benking.co.nz" },
    { hostname = "gym.benking.co.nz",        http_host_header = "gym.benking.co.nz" },
    { hostname = "grocery.benking.co.nz",    http_host_header = "grocery.benking.co.nz" },
    { hostname = "wordle.benking.co.nz",     http_host_header = "wordle.benking.co.nz" },
    { hostname = "benking.co.nz",            http_host_header = "benking.co.nz" },
    { hostname = "admin.benking.co.nz",      http_host_header = "admin.benking.co.nz" },
    { hostname = "app.benking.co.nz",        http_host_header = "app.benking.co.nz" },
    { hostname = "docs.benking.co.nz",       http_host_header = "docs.benking.co.nz" },
    { hostname = "ansible.benking.co.nz",    http_host_header = "ansible.internal.benking.co.nz" },
    { hostname = "proxmox.benking.co.nz",    http_host_header = "proxmox.internal.benking.co.nz" },
    { hostname = "job-hunter.benking.co.nz", http_host_header = "job-hunter.benking.co.nz" },
    { hostname = "jira.benking.co.nz",       http_host_header = "jira.internal.benking.co.nz" },
    { hostname = "mcu.benking.co.nz",        http_host_header = "mcu.internal.benking.co.nz" },
    { hostname = "money.benking.co.nz",      http_host_header = "money.internal.benking.co.nz" },
    { hostname = "notepad.benking.co.nz",    http_host_header = "notepad.benking.co.nz" },
    { hostname = "sftp.benking.co.nz",       http_host_header = "sftp.benking.co.nz" },
    # heater.benking.co.nz — NOT Access-gated (no apps.tf entry, intentional).
    # Public one-button "turn the Goldair heater off" page + webhook proxy,
    # guarded by the 43-char webhook id. Rewrites to heater.internal so Caddy's
    # on-demand-TLS *.internal block serves it. See homelab-ansible-playbooks
    # files/Caddyfile @heater and config/automations.yaml.
    { hostname = "heater.benking.co.nz",     http_host_header = "heater.internal.benking.co.nz" },
  ]
  main_tunnel_ssh_ingress = [
    { hostname = "ssh.benking.co.nz",            service = "ssh://192.168.1.50:22" },
    { hostname = "ssh-cloudflare.benking.co.nz", service = "ssh://localhost:22" },
  ]
}
