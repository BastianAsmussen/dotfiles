# AGENTS.md — Bastian's NixOS Dotfiles

## Overview

NixOS flake using **flake-parts** with **import-tree**: every `.nix` file
under `modules/` is auto-imported as a flake-parts module. No explicit
`imports` in `flake.nix`; `outputs` hands `import-tree ./modules` to
`mkFlake`.

| Host    | Role                       | Arch    | Bootloader   |
|---------|----------------------------|---------|--------------|
| epsilon | AMD desktop, home server   | x86_64  | Lanzaboote   |
| delta   | Intel laptop               | x86_64  | Limine       |
| eta     | Hetzner ARM cloud (public) | aarch64 | systemd-boot |
| iso     | Custom installer ISO       | x86_64  | n/a          |

WireGuard mesh in a star, eta is the hub.

- epsilon: *arr stack, Jellyfin, SearXNG, Monero node, qBittorrent bound to
  PIA, arctic vault backups, news sync to eta, primary-busy health check.
- eta: nginx stream TLS passthrough to epsilon (primary-mirror health checks
  toggle SNI routing to epsilon or a local fallback), nix cache
  `cache.asmussen.tech`, website, aarch64 remote builder.
- delta: niri desktop, WireGuard client, kanata, `max-jobs=0` so builds go to
  the cache host.

Less obvious inputs: niri (scrollable-tiling Wayland compositor),
noctalia-shell (bar, launcher, control center, notifications), schizofox
(hardened Firefox wrapper), stylix (theming), preservation (tmpfs root),
lanzaboote (Secure Boot, epsilon only).

## Version control

jujutsu colocated on git. **Never `git add` / `git commit` / `git branch`.**
Use `jj`. `git fetch origin` and `git push origin master` are the remote
boundary only. Commits are GPG-signed and carry a jj `Change-Id:` header.
Full working model: `jj-workflow` skill.

## Module conventions

Every module exposes itself via the flake:

```nix
# modules/nixosModules/**/*.nix
{ inputs, self, ... }:
{
  flake.nixosModules.<name> = { config, lib, pkgs, ... }: { };
}

# modules/homeManagerModules/**/*.nix
{ inputs, self, ... }:
{
  flake.homeModules.<name> = { config, lib, pkgs, osConfig ? null, ... }: { };
}
```

Flat files use the filename as the module name (`gopass.nix` ->
`self.homeModules.gopass`); multi-file modules import a `module.nix` that
re-exports. Files directly under `modules/` are flake-parts modules and may
declare `perSystem`, `flake`, or both.

Hosts live in `modules/nixosModules/hosts/<name>/` with `configuration.nix`
(defines `flake.nixosConfigurations.<name>` and
`flake.nixosModules.host<Name>`), `disko-config.nix` and
`hardware-configuration.nix`. Host modules import from `self.nixosModules.*`
and `self.homeModuleSets.*`; `home-manager.userModules.bastian` wires
home-manager to the host.

Options: `preferences.*` for per-host tunables, otherwise each feature module
owns its own namespace (`cfg = config.<feature>`). `lib.mkEnableOption` with
explicit default overrides. Descriptions are mandatory, sentence case.

Adding a module, a host, or a test: `nixos-add-module`, `nixos-add-host`,
`nixos-testing` skills.

## Secrets

sops-nix with age. `features/sops.nix` derives the age identity from the
host's SSH ed25519 key. Per-host secrets live in the private `nix-secrets`
input (`git+ssh://git@codeberg.org/BastianA/nix-secrets.git`). Declare with
`sops.secrets."my-secret" = { };` and read
`config.sops.secrets."my-secret".path`; identical in NixOS and home-manager
modules. See `nixos-sops-secrets`.

## Impermanence (preservation)

tmpfs root, persistent state bind-mounted from `/persist`. Each module
declares the state it owns; hosts declare only what no module owns. Home
modules use paths relative to `~`. A module a non-preservation host imports
guards with `lib.optionalAttrs (options ? persistence)`. See
`nixos-impermanence`.

## Conventions

- Format with `nix fmt` (treefmt wrapping nixfmt). Pre-commit and flake
  checks run deadnix, statix, nixfmt, flake-checker, check-yaml. No dead
  code, no unused variables.
- `nixpkgs.hostPlatform` defaults to `x86_64-linux`, `system.stateVersion`
  to `"26.05"`, `allowUnfree = true`.
- Danish keyboard layout, Caps Lock -> Escape. User `bastian`, UID 1000.
- Catppuccin Mocha, JetBrainsMono Nerd Font, Bibata Modern Ice cursor.
- Task runner is `just`; `just --list` or the `just` skill for recipes.
