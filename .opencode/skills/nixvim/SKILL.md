---
name: nixvim
description: Use this skill when the user needs to configure Neovim declaratively — editing the Catppuccin Mocha-themed config with 50+ plugins and 18 LSPs. Applies when discussing nixd LSP wiring, plugin changes, or the `neovim`/`neovim-minimal` packages, even without saying "nixvim".
metadata:
  input_rev: dbf9550dba8448b03e11d58e5695d6c44a464554
  input_hash: sha256-kjsEECqhpPnJWqhooXp6tWh2qGQftCPAo2G1GvZtKdw=
  when_to_use: nixvim, neovim config, nixvim modules, nixd LSP
---

## Pin check

`grep -A4 '"nixvim"' flake.lock | grep narHash`
Expected: `sha256-kjsEECqhpPnJWqhooXp6tWh2qGQftCPAo2G1GvZtKdw=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. Edit the core config in `modules/homeManagerModules/_nixvim-config.nix` (Catppuccin Mocha colorscheme, 50+ plugins, 18 LSPs).
2. Flake-parts integration: `modules/nixvim.nix` imports `inputs.nixvim.flakeModules.default`, defines `self.nixvimModules.default`.
3. Home-manager integration: `modules/homeManagerModules/nixvim.nix` imports `inputs.nixvim.homeModules.nixvm`, wires nixd LSP to host's flake.
4. Build with `nix build .#neovim` for the full package or use `neovim-minimal` for lightweight environments.

## Gotchas

- `_nixvim-config.nix` is excluded from import-tree's auto-import at `flake.nix:111` because it's not a flake-parts module. It's a raw nixvim config imported by `modules/nixvim.nix`.
- Nixd LSP is wired to the host's flake (`self.outPath` as the flake root). If nixd shows stale completions, the flake path may need updating.
## Verification

`nix build .#neovim 2>&1 | tail -3`
