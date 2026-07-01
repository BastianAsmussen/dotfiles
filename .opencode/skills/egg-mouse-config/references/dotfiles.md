# egg-mouse-config — Reference

## What it is

GUI configuration tool for EGG gaming mice (`github:BastianAsmussen/UnofficialEGGMouseConfig`). Allows adjusting CPI (sensitivity), polling rate, lift-off distance (LOD), and debounce settings from a Linux desktop.

## Why it's in the dotfiles

Epsilon is a gaming desktop. The EGG XM2/OP1 mouse needs on-Linux configuration without booting Windows.

## How it's wired

- **Input declaration:** `flake.nix:103-106`
- **Host import:** `modules/nixosModules/hosts/epsilon/configuration.nix:93` — `inputs.egg-mouse-config.nixosModules.default`
- **Enable:** `modules/nixosModules/hosts/epsilon/configuration.nix:729` — `programs.egg-mouse-config.enable = true`

## Hosts using it

| Host | How |
|------|-----|
| ε | Direct import + enable in host config |
