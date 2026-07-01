---
name: firefox-addons
description: Use this skill when the user needs to manage Firefox extensions declaratively — add, update, or audit version-pinned, hash-locked XPI derivations. Applies when working on browser extensions, even if the user doesn't say "firefox-addons" or "XPI".
metadata:
  input_rev: 6c2dd39e5bf2666b298ee3bdbf0dfd858911e8e3
  input_hash: sha256-YV++7tX9MN8Y1APD3BsXqLioBeKZjgFPxrT0YoD416A=
  when_to_use: firefox-addons, Firefox extensions, XPI derivations, extension SRI hashes
---

## Pin check

`grep -A4 '"firefox-addons"' flake.lock | grep narHash`
Expected: `sha256-YV++7tX9MN8Y1APD3BsXqLioBeKZjgFPxrT0YoD416A=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. Reference an extension at `pkgs.firefox-addons.<name>` — available anywhere the overlay is applied.
2. Install extensions via schizofox's `extraExtensions` in `modules/homeManagerModules/firefox.nix:41-49`.
3. To update all addons: `nix flake update firefox-addons`.

## Gotchas

- The overlay at `modules/overlays.nix:28-29` applies system-wide, but extensions only take effect when referenced in schizofox's `extraExtensions` list. Just adding the overlay does nothing visible.
- Standalone home-manager configs need the overlay separately at `modules/home-configurations.nix:20`.

See [references/dotfiles.md](references/dotfiles.md) for wiring details.

## Verification

`nix eval .#legacyPackages.x86_64-linux.firefox-addons.gopass-bridge.name`
