---
name: nixpkgs
description: Use this skill when the user needs to understand the primary package set — where packages come from, how nixos-unstable is pinned, and what happens when packages break. Applies when discussing package sources, the flake input graph, or dependency consistency across all hosts.
metadata:
  input_rev: 567a49d1913ce81ac6e9582e3553dd90a955875f
  input_hash: sha256-lrp67w8AulE9Ks53n27I45ADSzbOCn4H+CNW1Ck8B+8=
  when_to_use: nixpkgs, nix packages, NixOS unstable, package versions, nixosSystem
---

## Pin check

`grep -A4 '"nixpkgs"' flake.lock | grep narHash`
Expected: `sha256-lrp67w8AulE9Ks53n27I45ADSzbOCn4H+CNW1Ck8B+8=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. All packages come from nixpkgs (nixos-unstable). Host `configuration.nix` files build via `inputs.nixpkgs.lib.nixosSystem`.
2. 17 other inputs follow nixpkgs to maintain a single consistent package set.
3. When a package breaks on unstable, fall back to `pkgs.stable` via the nixpkgs-stable overlay.
4. Custom packages in `modules/packages/` are exposed via overlays in `modules/overlays.nix`.

## Gotchas

- Updating nixpkgs updates it for 17 dependent inputs that follow it. Most flake inputs don't have independent nixpkgs versions — they inherit from the root nixpkgs via `inputs.<input>.nixpkgs.follows = "nixpkgs"`.

See [references/dotfiles.md](references/dotfiles.md) for wiring details.

## Verification

`nix eval --raw .#nixosConfigurations.epsilon.pkgs.stdenv.hostPlatform.system`
