# winapps — Reference

## What it is

`winapps` (`github:winapps-org/winapps`) runs Windows applications on Linux via a Podman Windows VM + FreeRDP RemoteApp. Windows apps appear as native windows through RDP seamless mode.

## Why it's in the dotfiles

Run Microsoft Office and other Windows-only apps on Linux without a separate machine.

## How it's wired

- **Input declaration:** `flake.nix:98-101`
- **Feature module:** `modules/nixosModules/features/winapps.nix` (154 lines)
- **Options:** `winapps.windowsVersion` (10/11/2022), `ramSize` (default 8G), `cpuCores` (4), `diskSize` (64G), `rdpScale` (100/140/180), `sharedDir` (~/Windows)
- **What it sets up:** kernel modules (ip_tables, iptable_nat), kvm group, systemd-tmpfiles, zsh aliases, system packages (winapps, winapps-launcher, freerdp, podman-compose), sops-templated winapps.conf and compose.yaml
- **Secrets:** `winapps/rdp-user`, `winapps/rdp-pass`

## Hosts using it

| Host | How |
|------|-----|
| ε | `winapps.enable = true` |
| δ | `winapps.enable = true` |
