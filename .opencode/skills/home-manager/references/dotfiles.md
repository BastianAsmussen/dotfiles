# home-manager — Reference

## What it is

`home-manager` (`github:nix-community/home-manager`) integrates user-level configuration across every host via both NixOS-level and standalone paths.

## Why it's in the dotfiles

All user programs (git, zsh, tmux, firefox, nixvim, etc.) are declared via home-manager modules. This keeps user config portable and composable across hosts.

## How it's wired

### NixOS integration
- `modules/nixosModules/features/home-manager.nix:18` — imports `inputs.home-manager.nixosModules.home-manager`
- Defines `home-manager.userModules` option, maps to `home-manager.users` at line 34
- Sets `extraSpecialArgs = { inherit inputs pkgs self; }`

### Standalone home-manager
- `modules/home-configurations.nix:12` — `homeManagerConfiguration` builder for per-host portable configs
- Imports stylix, user info, then host-specific module lists (line 43-98)

### Host wiring
| Host | configuration.nix line |
|------|----------------------|
| ε | 751 |
| δ | 222 |
| μ | 59 |
| η | 354 |

### Profiles
| Profile | File | Modules | Hosts |
|---------|------|---------|-------|
| terminal | `profiles/terminal.nix:6-25` | 18 modules (git, zsh, tmux, nixvim, etc.) | ε, δ, μ |
| desktop | `profiles/desktop.nix:4-11` | 5 modules (alacritty, firefox, nixcord, etc.) | ε, δ |
| bastian | `profiles/bastian.nix` | Shared packages + GPG trust | ε, δ |

## Hosts using it

| Host | How |
|------|-----|
| ε | NixOS + standalone |
| δ | NixOS + standalone |
| η | NixOS only |
| μ | NixOS only |
