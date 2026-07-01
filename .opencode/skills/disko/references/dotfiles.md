# disko — Reference

## What it is

[disko](https://github.com/nix-community/disko) is a declarative disk partitioning tool for NixOS. Write a Nix expression describing the desired partition layout and disko applies it idempotently, replacing manual `fdisk`, `cryptsetup`, and `mkfs` steps.

## Why it's in the dotfiles

Three hosts need reproducible, auditable disk layouts:
- **Epsilon**: 4 physical disks (2x NVMe RAID1, 1x HDD media, 1x HDD vault) with FIDO2-bound LUKS, tmpfs root, and Btrfs subvolumes.
- **Delta**: Single NVMe with FIDO2 LUKS → LVM → Btrfs (root, nix, home subvolumes).
- **Eta**: Hetzner VPS with single disk, LUKS → LVM → Btrfs, provisioned remotely via nixos-anywhere.

## How it's wired

- **Input declaration:** `flake.nix:29-32`
- **flake-parts integration:** `modules/flake-parts.nix:4` — `inputs.disko.flakeModules.default`
- **Per-host configs:** `modules/nixosModules/hosts/<host>/disko-config.nix`
- **Host imports:** Each `configuration.nix` imports `inputs.disko.nixosModules.disko` + `self.diskoConfigurations.host<Name>`:
  - Epsilon: `configuration.nix:90,94`
  - Delta: `configuration.nix:25,30`
  - Eta: `configuration.nix:43,47`

## Partitioning patterns

- **Epsilon** (4 disks, tmpfs root): `/` is tmpfs. Two NVMe drives form Btrfs RAID1 for `/persist` and `/nix`. Two HDDs are single-disk Btrfs for `/srv/media` and `/srv/arctic-vault`. All LUKS use FIDO2.
- **Delta** (1 disk, persistent root): Single NVMe → LUKS → LVM → Btrfs with `/root`, `/nix`, `/home` subvolumes.
- **Eta** (1 disk, tmpfs root): Single disk → LUKS → LVM → Btrfs with `/persist`, `/nix`, `/home`.

## OpenTofu integration

Eta's provisioning in `tofu/` uses nixos-anywhere, which reads the disko configuration to partition the raw Hetzner cloud server.

## Hosts using it

| Host | File | Key line |
|------|------|----------|
| ε | `modules/nixosModules/hosts/epsilon/disko-config.nix` | line 2 |
| δ | `modules/nixosModules/hosts/delta/disko-config.nix` | line 2 |
| η | `modules/nixosModules/hosts/eta/disko-config.nix` | line 2 |
