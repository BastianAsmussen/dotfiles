# nixpkgs — Reference

## What it is

`nixpkgs` is the official Nix package repository tracked on `nixos-unstable` (`github:NixOS/nixpkgs/nixos-unstable`). It provides every package, NixOS module, and library function.

## Why it's in the dotfiles

The single source of truth for all packages across all hosts. Every host builds against the same nixpkgs revision.

## How it's wired

- **Input declaration:** `flake.nix:5`
- **Follows:** 17 other inputs follow nixpkgs for consistency
- **System closure:** `inputs.nixpkgs.lib.nixosSystem` in host configs
- **Standalone HM:** `modules/home-configurations.nix` uses same nixpkgs
- **Custom lib:** `modules/lib.nix` extends `inputs.nixpkgs.lib`

## Hosts using it

| Host | How |
|------|-----|
| All | Every host builds against this nixpkgs |
