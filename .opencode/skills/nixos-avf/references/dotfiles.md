# nixos-avf — Reference

## What it is

[nixos-avf](https://github.com/nix-community/nixos-avf) provides NixOS modules to boot a NixOS VM under Android's built-in Virtualization Framework (AVF). It handles kernel config, initrd wiring, and `crosvm` integration.

## Why it's in the dotfiles

Mu is a Pixel phone. Running NixOS under AVF gives a full Linux environment without replacing Android — no custom ROM or bootloader unlock needed.

## How it's wired

- **Input declaration:** `flake.nix:15`
- **Mu import:** `modules/nixosModules/hosts/mu/configuration.nix:29` — `inputs.nixos-avf.nixosModules.avf`
- **AVF wiring:** Line 49-52 (topology guest), line 54 (`avf.defaultUser`), line 57 (`nixpkgs.hostPlatform = "aarch64-linux"`)
- **Other mu imports:** `stylix`, `nix`, `nh`, `homeManager`, `topology` (lines 30-44)

## Hosts using it

| Host | How |
|------|-----|
| μ | Only host — AVF guest on Android |
