---
name: disko
description: Use this skill when the user needs to configure disk partitioning in NixOS — declaratively define GPT, LUKS, LVM, Btrfs, and tmpfs layouts. Applies when setting up disks, formatting, or provisioning hosts with nixos-anywhere, even if the user doesn't say "disko".
metadata:
  input_rev: ff8702b4de27f72b4c78573dfb89ec74e36abdf1
  input_hash: sha256-RxWs5ND31KzTG7wvMM+PMfUjyNpmIEr999lqNARaM5o=
  when_to_use: disko, disk partitioning, LUKS, btrfs, LVM, tmpfs root, format disk, nixos-anywhere, diskoConfigurations
---

## Pin check

`grep -A4 '"disko"' flake.lock | grep narHash`
Expected: `sha256-RxWs5ND31KzTG7wvMM+PMfUjyNpmIEr999lqNARaM5o=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. Find the host's `disko-config.nix` under `modules/nixosModules/hosts/<host>/`.
2. Declare the disk layout (GPT, LUKS, LVM, Btrfs subvolumes, tmpfs) in the config, exporting it as `self.diskoConfigurations.host<Name>`.
3. Import both `inputs.disko.nixosModules.disko` and `self.diskoConfigurations.host<Name>` in the host's `configuration.nix`.
4. For remote provisioning (eta), use `nixos-anywhere` — it reads the disko config directly.

## Gotchas

- Disko configs live in host directories (`modules/nixosModules/hosts/<host>/disko-config.nix`), referenced as `self.diskoConfigurations.host<Name>` — not `self.diskoConfigurations.<name>`.
- The `just install HOST` command never runs disko. You must run `just disko HOST` first as a separate, destructive step.

See [references/dotfiles.md](references/dotfiles.md) for wiring details.

## Verification

`nix eval .#diskoConfigurations.hostEpsilon.config.disko.devices.disk | jq 'keys'`
