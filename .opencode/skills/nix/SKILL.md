---
name: nix
description: Use this skill when the user needs to understand the dotfiles architecture or make structural changes — adding hosts, features, modules, or understanding how the module system, import-tree, flake-parts, and secrets wiring fit together. Trigger: "dotfiles", "NixOS config", "module system", "architecture".
metadata:
  when_to_use: dotfiles, NixOS configuration, host config, module system, dotfiles architecture
---

# Nix — Dotfiles Architecture

When invoked about a specific flake input, also load that input's dedicated skill for detailed pin-aware guidance.

## Architecture overview

```
flake.nix → flake-parts.lib.mkFlake → inputs.import-tree ./modules
```

Every `.nix` file under `modules/` is auto-discovered by `import-tree` and treated as a flake-parts module. `flake.nix` is only ~112 lines — it declares all inputs and the single `outputs` call. All logic lives in `modules/`.

## Module system layers

### `modules/flake-parts.nix` — root setup
- Imports `disko`, `home-manager`, and `flake-parts` flakeModules
- Sets `systems = ["aarch64-linux" "x86_64-linux"]`, `debug = true`
- Declares `wrapperModules` option for the wrapping system

### `modules/nixosModules/base/` — shared foundation
`base.nix`, `grub.nix`, `language.nix`, `lanzaboote.nix`, `limine.nix`, `misc.nix`, `monitors.nix`, `start.nix`, `systemd-boot.nix`, `user.nix`. Every host imports a subset.

### `modules/nixosModules/features/` — feature modules
Self-contained NixOS modules (ssh, wireguard, niri, jellyfin, etc.). Pattern:
```nix
{ flake.nixosModules.<name> = { config, lib, ... }: {
  options.<name>.enable = lib.mkEnableOption "...";
  config = lib.mkIf config.<name>.enable { ... };
}; }
```

### `modules/nixosModules/hosts/` — host configs
`epsilon`, `delta`, `eta`, `mu`, `iso` (+ `_example/` template). Each has `configuration.nix` and `disko-config.nix`.

### `modules/homeManagerModules/` — user programs + profiles
Modules for git, zsh, tmux, firefox, etc. Grouped into profiles (`bastian`, `desktop`, `terminal`) assembled per-host in `modules/home-configurations.nix`.

### `modules/packages/` — custom derivations
Custom packages exposed via overlays in `modules/overlays.nix`.

### `modules/wrappedPrograms/` — wrapped programs
`niri.nix`, `noctalia.nix`, `wlr-which-key.nix`.

## Data flow

Each module file sets options on:
- `flake.nixosConfigurations.<host>` — Host NixOS configs
- `flake.nixosModules.<name>` — Reusable NixOS modules
- `flake.homeConfigurations` — Standalone home-manager configs
- `flake.homeModules.<name>` — Reusable home-manager modules
- `perSystem.packages.<name>` — Per-system packages
- `flake.overlays.<name>` — Package overlays

## Adding a host

```
just add-host NAME
```

1. Edit `modules/nixosModules/hosts/<name>/configuration.nix` — add feature imports
2. Edit `modules/nixosModules/hosts/<name>/disko-config.nix` — disk layout
3. Edit `modules/nixosModules/hosts/<name>/hardware-configuration.nix` — hardware specifics
4. Add to `modules/home-configurations.nix` — home-manager modules

## Adding a feature

Create `modules/nixosModules/features/<name>.nix`:
```nix
{ flake.nixosModules.<name> = { config, lib, ... }: {
  options.<name>.enable = lib.mkEnableOption "...";
  config = lib.mkIf config.<name>.enable { ... };
}; }
```
Import in host config: `self.nixosModules.<name>`

## Adding a home-manager module

Create `modules/homeManagerModules/<name>.nix`:
```nix
{ flake.homeModules.<name> = { ... }: { ... }; }
```
Add to the appropriate profile or host module list in `modules/home-configurations.nix`.

## Adding a package

Create `modules/packages/<name>.nix`:
```nix
{ perSystem = { pkgs, ... }: { packages.<name> = ...; }; }
```
Add to the `additions` overlay in `modules/overlays.nix`.

## Theme system

Catppuccin Mocha, defined in `modules/theme.nix`:
- `self.theme` — with `#` prefix (e.g. `"#89b4fa"`)
- `self.themeNoHash` — hash stripped (e.g. `"89b4fa"`)
Use `self.themeNoHash.baseXX` in wrapped programs. Stylix applies theming system-wide.

## Secrets

- Public values: `inputs.nix-secrets.*`
- Encrypted file paths: `config.sops.secrets."<path>".path`
- Templated configs: `config.sops.templates."<name>".path`
- **Never hardcode secrets.** The secrets repo is private — use `mkForce`/`mkDefault` for test bypasses.

## Conventions

- **Formatting:** `nixfmt-tree` via `just fmt`
- **Commits:** Conventional Commits (`feat(scope):`, `fix(scope):`, `docs:`, `chore:`, `refactor:`)
- **Never delete `flake.lock`** — use `just update` or `nix flake update <input>`
- **Never hardcode `/home/bastian`** — use `config.preferences.user.name`
- **Imports order:** External → hardware/disko → base → Nix → security → features → host-specific
- **Module naming:** camelCase for features, `hostCapitalized` for host modules

## Key commands

| Command | Purpose |
|---|---|
| `just fmt` | Format all Nix files |
| `just check` | Full flake check |
| `just build HOST=epsilon` | Build a host without switching |
| `just rebuild` | Rebuild and switch current host |
| `just iso` | Build custom ISO |
| `just disko HOST` | Set up disks (destructive) |
| `just install HOST` | Install NixOS |
| `just add-host NAME` | Scaffold a new host |
| `just update [input]` | Update flake inputs |
| `nix develop` | Enter dev shell |

## Gotchas

- `import-tree` auto-imports every `.nix` file under `modules/` — don't create non-module `.nix` files there
- Disko configs live in host directories, referenced as `self.diskoConfigurations.host<Name>`
- Some hosts cross-reference each other's configs (e.g., eta reads epsilon's WireGuard IPs)
- `nix flake check` is slow on first run; use `just check --keep-going`
- The secrets repo is private — you cannot access values from `inputs.nix-secrets`
