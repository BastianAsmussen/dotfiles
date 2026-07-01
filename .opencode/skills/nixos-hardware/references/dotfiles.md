# nixos-hardware — Reference

## What it is

[nixos-hardware](https://github.com/NixOS/nixos-hardware) is a community-maintained collection of NixOS modules that apply hardware-specific kernel modules, kernel parameters, udev rules, and firmware packages.

## Why it's in the dotfiles

Two radically different x86_64 machines (AMD desktop + Intel laptop) need diverging hardware tuning.

## How it's wired

- **Input declaration:** `flake.nix:16` — `nixos-hardware.url = "github:NixOS/nixos-hardware/master"`
- **Epsilon (AMD desktop):** `configuration.nix:99` — `common-cpu-amd` (microcode, IOMMU, scheduler tuning)
- **Delta (Intel laptop):** `hardware-extra.nix:11-14`:
  - `common-cpu-intel` — Intel CPU microcode
  - `common-pc` — general PC defaults
  - `common-pc-laptop` — laptop power management
  - `common-pc-ssd` — SSD TRIM/discard
  - Line 17: `services.thermald` explicitly enabled

## Hosts using it

| Host | How |
|------|-----|
| ε | `common-cpu-amd` |
| δ | `common-cpu-intel`, `common-pc`, `common-pc-laptop`, `common-pc-ssd` |
