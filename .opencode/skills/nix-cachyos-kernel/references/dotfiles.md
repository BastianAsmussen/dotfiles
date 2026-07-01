# nix-cachyos-kernel — Reference

## What it is

[nix-cachyos-kernel](https://github.com/xddxdd/nix-cachyos-kernel) packages the CachyOS kernel with BORE (Burst-Oriented Response Enhancer) CPU scheduler, LTO, and aggressive compilation flags.

## Why it's in the dotfiles

Epsilon is a gaming desktop (Steam, Proton, Lutris, Gamescope). The BORE scheduler favors interactive/low-latency tasks. ntsync replaces Wine's userspace esync/fsync for lower CPU overhead in Proton titles.

## How it's wired

- **Input declaration:** `flake.nix:17` — `nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release"`
- **Gaming module:** `modules/nixosModules/features/gaming.nix:12-18` — `nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ]`, `boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto`
- **ntsync:** `modules/nixosModules/features/gaming.nix:22` — `boot.kernelModules = [ "ntsync" ]`, udev rule at line 109-111
- **Epsilon import:** `configuration.nix:66`
- **SafeMode fallback:** `configuration.nix:756` — `boot.kernelPackages = mkForce pkgs.linuxPackages_latest`

## Hosts using it

| Host | How |
|------|-----|
| ε | Via gaming feature module |
