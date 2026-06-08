locals {
  hosts_dir  = "${path.module}/../modules/nixosModules/hosts"
  flake_root = abspath("${path.module}/..")

  host_files = fileset(local.hosts_dir, "*/host.tf.json")
  hosts = {
    for f in local.host_files :
    jsondecode(file("${local.hosts_dir}/${f}")).hostname => jsondecode(file("${local.hosts_dir}/${f}"))
  }

  hcloud_hosts = { for name, h in local.hosts : name => h if h.provider == "hcloud" }

  # Hosts tofu provisions a server for declare a server_type. Existing hosts
  # (e.g. eta) omit it and are reprovisioned in place at their known IP.
  managed_hosts = { for name, h in local.hcloud_hosts : name => h if can(h.server_type) }
}

# Only needed to seed the deploy key onto a freshly provisioned server's
# placeholder image. Unmanaged hosts (e.g. eta) reach the server over their
# known IP with var.deploy_ssh_key directly, so the key resource is skipped.
resource "hcloud_ssh_key" "deploy" {
  count      = length(local.managed_hosts) > 0 ? 1 : 0
  name       = "nixos-deploy"
  public_key = file("${path.module}/../keys/ssh-hetzner-deploy.pub")
}

resource "hcloud_server" "host" {
  for_each = local.managed_hosts

  name        = each.value.hostname
  server_type = each.value.server_type
  location    = each.value.location
  image       = "debian-12" # Placeholder OS; nixos-anywhere kexecs and reinstalls over it.
  ssh_keys    = [hcloud_ssh_key.deploy[0].id]

  lifecycle {
    ignore_changes = [image, ssh_keys]
  }
}

module "deploy" {
  source   = "github.com/nix-community/nixos-anywhere//terraform/all-in-one"
  for_each = local.hcloud_hosts

  nixos_system_attr      = "${local.flake_root}#nixosConfigurations.${each.value.hostname}.config.system.build.toplevel"
  nixos_partitioner_attr = "${local.flake_root}#nixosConfigurations.${each.value.hostname}.config.system.build.diskoScript"

  target_host     = try(hcloud_server.host[each.key].ipv4_address, var.host_ipv4[each.key])
  instance_id     = try(hcloud_server.host[each.key].id, each.value.hostname)
  install_user    = "root"
  install_ssh_key = var.deploy_ssh_key

  # Existing hosts: carry the enrolled host key so the sops age identity
  # survives the wipe, and feed disko the LUKS passphrase from pass.
  copy_host_keys     = try(each.value.copy_host_keys, false)
  extra_files_script = try(each.value.extra_files_script, null)
  disk_encryption_key_scripts = try(each.value.luks, false) ? [{
    path   = "/tmp/disk-1.key"
    script = "${path.module}/scripts/luks-key-${each.value.hostname}.sh"
  }] : []
}

output "server_ips" {
  value = { for name, server in hcloud_server.host : name => server.ipv4_address }
}
