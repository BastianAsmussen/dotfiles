# nix-index-database — Reference

## What it is

[nix-index-database](https://github.com/nix-community/nix-index-database) provides a pre-built database of all packages in nixpkgs, enabling command-not-found suggestions and the `, <cmd>` (comma) runner.

## Why it's in the dotfiles

Ergonomic shell experience: mistyped commands get nixpkgs suggestions, and `, cowsay hello` runs any package without installing it.

## How it's wired

### NixOS module
| Host | File | Line |
|------|------|------|
| ε | `configuration.nix` | 96 |
| δ | `configuration.nix` | 27 |
| μ | `configuration.nix` | 30 |

Eta is headless and has no terminal profile.

### Home-manager module
`modules/homeManagerModules/nix-index.nix` — `programs.nix-index` with bash/zsh integration and comma via the terminal profile.

### Zsh integration
`modules/homeManagerModules/zsh.nix:133-138` — sources `command-not-found.sh` into zsh's `command_not_found_handler`.

## Hosts using it

| Host | How |
|------|-----|
| ε | NixOS module + HM module via terminal profile |
| δ | NixOS module + HM module via terminal profile |
| μ | NixOS module + HM module via terminal profile |
