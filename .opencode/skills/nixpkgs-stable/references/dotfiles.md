# nixpkgs-stable — Reference

## What it is

`nixpkgs-stable` is a second nixpkgs instance pinned to the `nixos-25.11` branch (`github:NixOS/nixpkgs/nixos-25.11`). It serves as a safety hatch for packages that break on unstable.

## Why it's in the dotfiles

When a package breaks on nixos-unstable, a host or module can fall back to the stable version without downgrading the entire system.

## How it's wired

- **Input declaration:** `flake.nix:6` — `nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11"`
- **Overlay:** `modules/overlays.nix:44-50` — merges stable packages into `pkgs.stable`

## Hosts using it

| Host | How |
|------|-----|
| All | Available as `pkgs.stable` across all hosts via the overlay |
