# Hetzner Cloud IaC

OpenTofu provisions Hetzner Cloud servers and hands them to
[nixos-anywhere](https://github.com/nix-community/nixos-anywhere), which
partitions (via each host's disko `diskoScript`) and installs the host's NixOS
configuration. A host opts in by shipping a `host.tf.json` in its host directory:

```json
{ "hostname": "zeta", "provider": "hcloud", "server_type": "cax11", "location": "hel1" }
```

`main.tf` globs every `modules/nixosModules/hosts/*/host.tf.json`, so adding a
host is a drop-in. `zeta` is a throwaway CAX (Ampere ARM) box for validating the
flow before it is pointed at a production host.

## Prerequisites

- A Hetzner Cloud API token, stored in your `nix-secrets` sops. Adding it there
  is a manual step you perform yourself.
- The deploy key `keys/ssh-epsilon.pub` is authorized on every provisioned
  server (see `hcloud_ssh_key.deploy` in `main.tf`).
- Enter the tooling shell: `nix develop .#infra`.

## Providing the token

OpenTofu reads the token from `var.hcloud_token`, which is populated from the
`TF_VAR_hcloud_token` environment variable. Export it into your shell yourself
from your secret store before running OpenTofu; never commit it. The token must
not be scripted into this repo.

## Running

```sh
cd tofu
tofu init      # fetches the hcloud provider, writes .terraform.lock.hcl
tofu plan
tofu apply
```

State is local (`terraform.tfstate`, gitignored). Back it up out of band.

## aarch64 builds

`zeta` and `eta` are aarch64. The deploying host must be able to build aarch64
(binfmt emulation or a remote builder; epsilon already offloads aarch64 builds).
Alternatively pass `build_on_remote = true` to the `module.deploy` block to build
on the target itself.

## Notes

- `tofu apply` builds `.#nixosConfigurations.<host>...toplevel` from the flake at
  the repo root, so commit host changes before deploying (a flake path ref uses
  the committed tree).
- `hcloud_server` ignores `image`/`ssh_keys` drift after install; nixos-anywhere
  owns the running system from then on.
