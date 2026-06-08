variable "hcloud_token" {
  type        = string
  sensitive   = true
  description = "Hetzner Cloud API token. Supply via the TF_VAR_hcloud_token environment variable from your own secret store; never commit it."
}

variable "deploy_ssh_key" {
  type        = string
  sensitive   = true
  description = "Passphraseless private key matching keys/ssh-hetzner-deploy.pub, used by nixos-anywhere. Supply via TF_VAR_deploy_ssh_key from your secret store."
}

variable "host_ipv4" {
  type        = map(string)
  default     = {}
  description = "IPv4 of existing (unmanaged) hosts, keyed by hostname. Supply via TF_VAR_host_ipv4 as JSON, e.g. {\"eta\":\"x.x.x.x\"}."
}
