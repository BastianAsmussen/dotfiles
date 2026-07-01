# lanzaboote — Reference

## What it is

[lanzaboote](https://github.com/nix-community/lanzaboote) enables UEFI Secure Boot by signing Unified Kernel Images (UKIs) with a custom Platform Key, managing the key hierarchy via `sbctl`.

## Why it's in the dotfiles

Epsilon uses tmpfs root — Secure Boot ensures only signed kernels can boot, preventing rootkit persistence across reboots.

## How it's wired

- **Input declaration:** `flake.nix:34-37`, pinned to v1.1.0
- **Base module:** `modules/nixosModules/base/lanzaboote.nix`:
  - Line 10: imports `inputs.lanzaboote.nixosModules.lanzaboote`
  - Line 15: `boot.loader.systemd-boot.enable = lib.mkForce false`
  - Lines 23-34: `enable = true`, `pkiBundle = "/var/lib/sbctl"`, Microsoft keys included
  - Line 37: `sbctl` in `environment.systemPackages`
- **Epsilon import:** `configuration.nix:35` — `self.nixosModules.lanzaboote`
- **Persistence:** `configuration.nix:369-376` — persists `/var/lib/sbctl` with mode `0700`

## Hosts using it

| Host | How |
|------|-----|
| ε | Only host with Secure Boot; delta uses Limine, eta uses systemd-boot, mu has no bootloader |
