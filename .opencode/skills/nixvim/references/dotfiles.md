# nixvim — Reference

## What it is

`nixvim` (`github:nix-community/nixvim`) declares Neovim configuration as Nix modules with type-checked options for every plugin.

## Why it's in the dotfiles

Neovim is the primary editor. Declaring it in Nix ensures reproducible config across hosts with type-safe options.

## How it's wired

- **Input declaration:** `flake.nix:56-59`
- **Flake-parts integration:** `modules/nixvim.nix:3-4` — imports `inputs.nixvim.flakeModules.default`, enables packages and checks
- **Config module:** `modules/nixvim.nix:12-17` — `self.nixvimModules.default` wrapping `_nixvim-config.nix` (1054 lines)
- **CI validation:** `modules/nixvim.nix:27-35` — `nixvimConfigurations.default` via `evalNixvim`
- **Home-manager:** `modules/homeManagerModules/nixvim.nix:7-86` — imports `inputs.nixvim.homeModules.nixvm`, disables stylix, wires nixd LSP to host flake
- **Custom packages:** `modules/packages/neovim.nix` — `neovim` (full) and `neovim-minimal` (lightweight)
- **Usage:** Included via terminal profile (`profiles/terminal.nix:17`)

## Hosts using it

| Host | How |
|------|-----|
| ε | Via terminal profile |
| δ | Via terminal profile |
| μ | Via terminal profile |
