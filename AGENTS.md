# AGENTS.md — Bastian's NixOS Dotfiles

## Overview

This is a NixOS configuration flake using **flake-parts** with
**import-tree** — every `.nix` file under `modules/` is auto-imported
as a flake-parts module.  No explicit `imports` in `flake.nix`; the
`outputs` function hands `import-tree ./modules` to `mkFlake`.

Three physical hosts plus an ISO:

| Host      | Role                          | Arch     | Bootloader     |
|-----------|-------------------------------|----------|----------------|
| epsilon   | AMD desktop, home server      | x86_64   | Lanzaboote     |
| delta     | Intel laptop                  | x86_64   | Limine         |
| eta       | Hetzner ARM cloud (public)    | aarch64  | systemd-boot   |
| iso       | Custom installer ISO           | x86_64   | —              |

All three hosts connect via a WireGuard mesh (star: eta is hub).
Epsilon runs the home services (Jellyfin, *arr stack, qBittorrent,
Monero, SearXNG). Eta is the internet-facing TLS passthrough proxy,
Nix cache mirror, and remote builder.

## Version Control (jujutsu)

This repo uses **jujutsu (`jj`)** as the version-control front-end,
**colocated on top of git** — `.jj/` and `.git/` coexist, so both `jj`
and `git` work. The `master` bookmark tracks the git `master` branch,
and `origin` is `ssh://git@codeberg.org/BastianA/dotfiles.git`.

**Never use `git add` / `git commit` / `git branch` for normal work.**
Use `jj` instead. The working copy is a single anonymous change; you
describe it rather than committing:

```sh
jj st           # status (like git status, shows working-copy changes)
jj describe -m "feat(module): add ..."   # set the change description
jj new          # start a new change (like a branch, but no name needed)
jj squash       # fold the working copy into the parent change
jj log          # history (default command)
```

`git` is still used for the push/pull boundary (jj has no remote
transport of its own):

```sh
git fetch origin
git push origin master
```

Commits are GPG-signed (`sign-on-push`, key `0xD92D668B77A29897`) and
carry a jj `Change-Id:` header. See the `jj-workflow` skill for the
full working model.

## Repository Layout

```
.
├── flake.nix          # inputs + mkFlake with import-tree
├── flake.lock         # lock file, updated weekly
├── justfile           # task runner (just rebuild/upgrade/check/iso/...)
├── shell.nix          # compatibility nix-shell for non-flake installers
├── statix.toml        # statix lint ignore list
├── modules/
│   ├── flake-parts.nix        # flake-parts wiring (systems, perSystem pkgs)
│   ├── home-configurations.nix # standalone home-manager configs (bastian@<host>)
│   ├── dev-shell.nix          # nix develop default shell
│   ├── checks.nix             # deadnix, statix, flake-checker checks
│   ├── formatter.nix          # treefmt + nixfmt
│   ├── pre-commit.nix         # git-hooks (deadnix, statix, nixfmt, flake-checker, check-yaml)
│   ├── lib.nix                # customLib → self.lib.custom bridge
│   ├── overlays.nix           # additions, firefox-addons, modifications, stable-packages
│   ├── theme.nix              # Catppuccin Mocha base16 palette
│   ├── nixvim.nix             # nixvim flake module wiring
│   ├── nixos-tests.nix        # NixOS eval + VM tests
│   ├── templates/templates.nix # dev env templates
│   ├── tofu.nix               # OpenTofu infra devShell
│   ├── topology.nix           # nix-topology network diagram
│   ├── lib/                   # custom library functions
│   │   ├── keys.nix           #   key selection helpers
│   │   ├── math/              #   math (base, crypto, random, trig)
│   │   ├── net.nix            #   network helpers
│   │   └── units.nix          #   unit conversions
│   ├── packages/              # custom packages
│   ├── nixosModules/
│   │   ├── base/              # base system modules
│   │   ├── features/          # feature modules
│   │   └── hosts/             # per-host configurations
│   ├── homeManagerModules/    # home-manager modules
│   │   └── profiles/          # aggregated profiles (bastian, desktop, terminal)
│   ├── wrappedPrograms/       # niri & noctalia wrapper-modules
│   └── tests/                 # unit tests for lib functions
├── keys/                      # public keys (SSH, age, GPG, mTLS CA)
├── assets/
│   ├── icons/                 # user avatar
│   └── wallpapers/            # wallpapers (tokyo.png)
├── docs/topology.svg          # network topology diagram
└── tofu/                      # Hetzner Cloud OpenTofu IaC
```

## Module Conventions

### Exposing modules

Every module **must** expose itself via the flake.  Two patterns:

**NixOS modules** (`modules/nixosModules/**/*.nix`):
```nix
{ inputs, self, ... }:
{
  flake.nixosModules.<name> = { config, lib, pkgs, ... }: {
    # module content
  };
}
```

**Home Manager modules** (`modules/homeManagerModules/**/*.nix`):
```nix
{ inputs, self, ... }:
{
  flake.homeModules.<name> = { config, lib, pkgs, osConfig ? null, ... }: {
    # module content
  };
}
```

Multi-file modules (e.g. `goxlr/`) import a `module.nix` that re-exports.
Flat single-file modules use the filename directly as the module name
(`gopass.nix` → `self.homeModules.gopass`).

### Top-level flake-parts modules

Files directly under `modules/` that are **not** in a subdirectory are
flake-parts modules.  They can declare `perSystem`, `flake` options, or
both.  Example:

```nix
# modules/dev-shell.nix
{
  perSystem = { pkgs, config, ... }: {
    devShells.default = pkgs.mkShell { ... };
  };
}
```

### Host module pattern

Each host has a directory under `modules/nixosModules/hosts/<name>/`
with at minimum:
- `configuration.nix` — defines `flake.nixosConfigurations.<name>` and `flake.nixosModules.host<Name>`
- `disko-config.nix` — disko partition layout
- `hardware-configuration.nix` — generated by `nixos-generate-config`

Host modules import from `self.nixosModules.*` and `self.homeModuleSets.*`.
The `home-manager.userModules.bastian` option wires home-manager to the host.

### Option declaration style

- `preferences.*` namespace for per-host tunables (monitors, user, noctalia, autostart)
- Each feature module declares its own option namespace (`cfg = config.<feature>`)
- `lib.mkEnableOption` with explicit default overrides
- Option descriptions are mandatory and written in sentence case

### Secrets

Managed via [sops-nix](https://github.com/Mic92/sops-nix) with age keys.
The sops module (`features/sops.nix`) derives the age identity from the
host's SSH ed25519 key.  Per-host secrets live in a separate private
repo (`nix-secrets`, input `git+ssh://git@codeberg.org/BastianA/nix-secrets.git`).

```nix
# In a NixOS module:
sops.secrets."my-secret" = { };
# Use: config.sops.secrets."my-secret".path

# In a home-manager module:
sops.secrets."my-secret" = { };
# Use: config.sops.secrets."my-secret".path
```

### Impermanence (preservation)

The `preservation` module (`features/preservation.nix`) manages a
tmpfs-on-root setup.  All persistent state is bind-mounted from
`/persist`.  Hosts declare what to persist:

```nix
persistence = {
  enable = true;
  directories = [ "/var/lib/acme" ... ];
  files = [ { file = "/var/lib/systemd/random-seed"; how = "symlink"; } ];
  user.directories = [ "Documents" ".config/sops" ... ];
};
```

## Key Technologies

| Technology          | Purpose                                      |
|---------------------|----------------------------------------------|
| niri                | Wayland compositor (scrollable-tiling)       |
| noctalia-shell      | Bar, launcher, control center, notifications |
| schizofox           | Hardened Firefox wrapper                     |
| stylix              | Catppuccin Mocha theme across all apps       |
| nixvim              | Neovim configuration                         |
| disko               | Declarative disk partitioning                |
| preservation        | tmpfs root + bind-mounted persistent state   |
| sops-nix            | Secrets management via age encryption        |
| nix-topology        | Network topology diagram generation          |
| nix-index-database  | Command-not-found index                      |
| lanzaboote          | Secure Boot signing (epsilon)                |

## Just Commands

| Command                    | Purpose                                         |
|----------------------------|-------------------------------------------------|
| `just rebuild [host]`     | Rebuild and switch                              |
| `just upgrade [host]`     | Update flake.lock + rebuild                     |
| `just update [input]`     | Update flake.lock without rebuilding            |
| `just build <host>`       | Build without switching                         |
| `just check`              | Full flake check                                |
| `just fmt`                | Format all Nix files (nixfmt)                   |
| `just iso`                | Build custom installer ISO                      |
| `just add-host <name>`    | Scaffold a new host from _example               |
| `just topology`           | Regenerate network diagram                      |
| `just vault`              | Trigger arctic backup snapshot                  |
| `just infra <args>`       | OpenTofu IaC commands                           |
| `just clean`              | Remove old generations                          |
| `just rollback`           | Restore flake.lock + rebuild                    |
| `just disko <host>`       | Partition disks (destructive!)                  |
| `just install <host>`     | Run nixos-install                               |
| `just fido2-enroll <dev>` | Enroll YubiKey for LUKS                         |
| `just age-keygen`         | Generate standalone age key                     |
| `just age-host-key`       | Derive age key from SSH host key                |

## CI (Forgejo Actions)

`.forgejo/workflows/ci.yml`:
1. `check` — `nix flake check --all-systems` on every push to master
2. `iso` — Builds deterministic ISO; creates a release if derivation changed
3. `topology` — Rebuilds `docs/topology.svg` and commits if changed

## Host-Specific Patterns

### epsilon (home server)
- All *arr services, Jellyfin, SearXNG, Monero node
- PIA VPN bound to qBittorrent
- WireGuard hub connections to eta and delta
- News aggregation + sync to eta
- Arctic vault backups
- Primary busy (health check service for eta's primary-mirror)

### eta (cloud server)
- TLS passthrough for epsilon's services via nginx stream proxy
- Primary-mirror health checks toggle SNI routing to epsilon or local fallback
- Nix cache (`cache.asmussen.tech`)
- Website hosting
- Remote builder for aarch64
- Receives news sync from epsilon

### delta (laptop)
- Desktop (niri + all terminal/desktop home modules)
- WireGuard client to eta
- Kanata keyboard remapping
- Nix cache offloads builds (max-jobs=0)

## Code Quality

- Pre-commit hooks: deadnix, statix, nixfmt, flake-checker, check-yaml
- Flake checks: deadnix, statix, flake-checker, NixOS eval tests, VM tests
- Format with `nix fmt` (treefmt wrapping nixfmt)
- All warnings treated seriously — no dead code, no unused variables

## Working With This Repo

### Adding a new feature module

1. Create `modules/nixosModules/features/<name>.nix`
2. Export via `flake.nixosModules.<name>`
3. Import in the host `configuration.nix` under the appropriate section
4. If it needs secrets, declare them with `sops.secrets`
5. If it needs persistent state and the host uses impermanence, document
   what directories need to be in `persistence.directories`

### Adding a new home-manager module

1. Create `modules/homeManagerModules/<name>.nix`
2. Export via `flake.homeModules.<name>`
3. If needed, add to profile aggregators (`profiles/terminal.nix`, `profiles/desktop.nix`)
4. Add to the host's `homeModuleSets` entry in `home-configurations.nix`

### Adding a new host

```sh
just add-host <name>
```
Then edit the generated `configuration.nix` to add the modules needed.
For managed hosts (Hetzner), add a `host.tf.json` in the host directory.

### Testing

- Eval tests: `modules/nixos-tests.nix` — add `mkEvalTest` entries
- VM tests: only for runtime behaviour (x86_64 only)
- Lib tests: `modules/tests/<topic>/default.nix`

## Preferences / Conventions

- `nixpkgs.hostPlatform` defaults to `x86_64-linux`
- `system.stateVersion` defaults to `"26.05"`
- `allowUnfree = true`
- nixfmt is the formatter
- Danish keyboard layout, Caps Lock → Escape
- User: bastian, UID 1000
- Catppuccin Mocha everywhere
- JetBrainsMono Nerd Font is the monospace font
- Bibata Modern Ice cursor theme
