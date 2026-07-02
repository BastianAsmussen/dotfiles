---
name: nix
description: Understand dotfiles architecture or make structural changes — adding hosts, features, modules, module system wiring, import-tree, flake-parts, secrets.
metadata:
  when_to_use: dotfiles, NixOS configuration, host config, module system, dotfiles architecture
---

# Nix — Dotfiles Architecture

When invoked about a specific flake input, also load that input's dedicated skill.

## Architecture

```
flake.nix → flake-parts.lib.mkFlake → inputs.import-tree ./modules
```

Every `.nix` file under `modules/` auto-discovered by `import-tree`. All logic lives in `modules/`.

## Module layers

- `modules/flake-parts.nix` — root: systems, debug, disko/home-manager/flake-parts imports
- `modules/nixosModules/base/` — shared foundation: boot, user, monitors, language
- `modules/nixosModules/features/` — feature modules. Pattern: `{ flake.nixosModules.<name> = { config, lib, ... }: { options.<name>.enable = lib.mkEnableOption "..."; config = lib.mkIf config.<name>.enable { ... }; }; }`
- `modules/nixosModules/hosts/` — epsilon, delta, eta, mu, iso + `_example/` template
- `modules/homeManagerModules/` — user programs, grouped into profiles per-host
- `modules/packages/` — custom derivations, exposed via `modules/overlays.nix`
- `modules/wrappedPrograms/` — niri, noctalia, wlr-which-key

## Data flow

Each module sets: `flake.nixosConfigurations.<host>`, `flake.nixosModules.<name>`, `flake.homeConfigurations`, `flake.homeModules.<name>`, `perSystem.packages.<name>`, `flake.overlays.<name>`.

## Adding things

```
just add-host NAME   # Scaffolds from _example/
```

- **Feature:** `modules/nixosModules/features/<name>.nix`, import as `self.nixosModules.<name>`
- **HM module:** `modules/homeManagerModules/<name>.nix`, add to profile in `modules/home-configurations.nix`
- **Package:** `modules/packages/<name>.nix`, add to `additions` overlay in `modules/overlays.nix`

## Theme

Catppuccin Mocha in `modules/theme.nix`: `self.theme` (with `#`), `self.themeNoHash` (stripped). Use `self.themeNoHash.baseXX`.

## Secrets

- Public: `inputs.nix-secrets.*`
- Encrypted file: `config.sops.secrets."<path>".path`
- Template: `config.sops.templates."<name>".path`
- **Never hardcode.** Use `mkForce`/`mkDefault` for test bypasses.

## Conventions

- Format: `nixfmt-tree` via `just fmt`
- Commits: Conventional Commits (`feat(scope):`, `fix(scope):`)
- Never delete `flake.lock`
- Never hardcode `/home/bastian` — use `config.preferences.user.name`
- Import order: External → hardware/disko → base → Nix → security → features → host-specific
- Module naming: camelCase features, `hostCapitalized` for host modules

## Missing commands

When command not found, use nix-shell:
```sh
nix shell nixpkgs#<pkg> -c <command> [args...]
```

Common: `nix shell nixpkgs#python3 -c python3`, `nix shell nixpkgs#nodejs -c node`, etc.

## Key commands

| Command | Purpose |
|---|---|
| `just fmt` | Format all Nix files |
| `just check` | Full flake check |
| `just build HOST=epsilon` | Build a host |
| `just rebuild` | Rebuild and switch |
| `just iso` | Build custom ISO |
| `just disko HOST` | Set up disks |
| `just install HOST` | Install NixOS |
| `just add-host NAME` | Scaffold new host |
| `just update [input]` | Update flake inputs |
| `nix develop` | Enter dev shell |

## Gotchas

- `import-tree` auto-imports every `.nix` under `modules/` — no non-module `.nix` files there
- Disko configs in host dirs, referenced as `self.diskoConfigurations.host<Name>`
- Hosts cross-reference (e.g. eta reads epsilon's WireGuard IPs)
- `nix flake check` slow first run; use `just check --keep-going`
- Secrets repo is private — can't access `inputs.nix-secrets` values
