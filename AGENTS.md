# AGENTS.md — dotfiles

NixOS configuration flake for multiple hosts (epsilon, delta, eta, mu, iso).
This document is a reference for AI agents working in this repository.

## Build / Test / Lint

All commands through the justfile:

```sh
# Format all Nix files (nixfmt-tree)
just fmt

# Full flake check (statix, deadnix, flake-checker, eval tests, VM tests)
just check

# Build a host without switching (HOST defaults to current hostname)
just build HOST=epsilon

# Rebuild and switch the current host
just rebuild

# Build custom ISO
just iso

# Enter dev shell
nix develop

# OpenTofu IaC
nix develop .#infra -c tofu -chdir=tofu plan
```

Pre-commit hooks: `deadnix`, `statix`, `nixfmt`, `flake-checker`, `check-yaml`.
Install with `nix develop` (shellHook auto-installs).

CI (Forgejo Actions) runs `nix flake check --all-systems` on push to `master`,
then conditionally builds an ISO release and regenerates `docs/topology.svg`.

## Architecture

**Purpose:** Declarative NixOS + home-manager configuration for a personal
infrastructure: desktop (epsilon), laptop (delta), Hetzner VPS (eta), Android
phone (mu), and a custom installer ISO. Secrets via sops-nix in a separate
private repo (`nix-secrets`).

**Module system:** flake-parts with `import-tree` — every `.nix` file under
`modules/` is auto-imported as a flake-parts module. Files act by setting
options on `flake.*`, `perSystem.*`, or defining NixOS/home-manager modules.

**Component tree:**

- `modules/flake-parts.nix` — root flake-parts setup (systems, debug flag)
- `modules/checks.nix` — static analysis: `deadnix`, `statix`, `flake-checker`
- `modules/formatter.nix` — `nixfmt-tree`
- `modules/dev-shell.nix` — default dev shell (git, fzf, jq, just)
- `modules/pre-commit.nix` — pre-commit hooks via git-hooks.nix
- `modules/overlays.nix` — overlays: custom packages, firefox-addons, nixpkgs-stable
- `modules/nixvim.nix` / `modules/homeManagerModules/nixvim.nix` — Neovim via nixvim, with nixd LSP wired to the host's flake
- `modules/theme.nix` — Catppuccin Mocha theme palette (`self.theme`, `self.themeNoHash`)
- `modules/topology.nix` — network topology diagram via nix-topology
- `modules/home-configurations.nix` — standalone home-manager configs per host
- `modules/nixos-tests.nix` — NixOS eval tests (assertion checks, no VM) + VM tests (x86_64 only)
- `modules/lib.nix` / `modules/lib/` — custom lib functions: key management, math, units
- `modules/nixosModules/base/` — essential system modules: bootloader, user, monitors, language
- `modules/nixosModules/features/` — feature flags: ssh, wireguard, niri, jellyfin, etc.
- `modules/nixosModules/hosts/` — per-host `nixosConfigurations` + `diskoConfigurations`
- `modules/homeManagerModules/` — home-manager modules: git, zsh, tmux, firefox, etc.
- `modules/packages/` — custom derivations
- `modules/wrappedPrograms/` — nix-wrapper-modules for niri compositor config
- `modules/templates/` — flake templates for C, C#, Go, Haskell, Python, Rust, Zig

**Data flow:** `flake.nix` → `flake-parts.lib.mkFlake` → `import-tree ./modules` →
auto-imports every module → each module sets `flake.nixosConfigurations.<host>`,
`flake.homeConfigurations`, `flake.nixosModules.<name>`, or `flake.homeModules.<name>`.

## Key Files & Directories

| Path | Purpose |
|------|---------|
| `flake.nix` | Flake entry point; declares all inputs |
| `flake.lock` | Pinned flake inputs (commit this) |
| `justfile` | Task runner: build, test, deploy, install |
| `shell.nix` | Fallback shell (non-flake), exports `NIX_CONFIG` |
| `statix.toml` | statix linter config (ignores `tofu/.terraform`) |
| `todo.txt` | Personal task tracker with priority tags (A/B/C) |
| `modules/` | All flake-parts modules (auto-imported) |
| `modules/nixosModules/hosts/<host>/` | Host definition: `configuration.nix` + `disko-config.nix` + `hardware-configuration.nix` |
| `modules/nixosModules/hosts/_example/` | Template for new hosts (`just add-host <name>`) |
| `keys/` | Public keys (SSH, Age, GPG, certs) — safe to commit |
| `tofu/` | OpenTofu for Hetzner Cloud provisioning + nixos-anywhere deploy |
| `assets/` | Wallpapers, icons |
| `docs/topology.svg` | Auto-generated network diagram (CI updates it) |
| `.forgejo/workflows/ci.yml` | CI: flake check → ISO build + topology update |

## Coding Conventions

- **Nix formatting:** `nixfmt-tree` via `just fmt`. All files must pass.
- **Module pattern:** Every file under `modules/` is a function `{ inputs, self, ... }: { flake.<...> = ...; }`. Host modules additionally produce `nixosConfigurations.<name>`.
- **Naming:** Host modules export `hostCapitalized` (e.g., `hostEpsilon`). Feature modules use camelCase matching the file name (e.g., `self.nixosModules.luksFido2`).
- **Secrets:** Never hardcode. Use `inputs.nix-secrets.*` for public values, `config.sops.secrets."<path>".path` for secret files, `config.sops.templates."<name>".path` for templated secrets.
- **Theme:** Always use `self.themeNoHash.baseXX` (hash-stripped) for color references in wrapped programs.
- **Users:** Declare via `preferences.user` options (name, fullName, email). Avoid hardcoding `/home/bastian`.
- **Imports order in hosts:** External modules → hardware/disko → base → Nix → security → features → host-specific.

## Git Workflow

- **Branch:** `master` (single-branch, no PRs in this personal repo)
- **Commit style:** [Conventional Commits](https://www.conventionalcommits.org/)
  - Types: `feat`, `fix`, `docs`, `chore`, `refactor`
  - Scopes: host name, feature name, or module (e.g., `feat(epsilon): ...`, `fix(nixvim): ...`)
- **Push triggers:** CI on push to master; topology auto-committed as `docs: update topology diagram [skip ci]`

## Tips for AI Agents

### Common pitfalls
- **Never delete `flake.lock`** — it pins all inputs. Use `just update` or `nix flake update <input>`.
- **Flake inputs are git-tracked.** After changing `flake.nix` inputs, run `nix flake update` and commit the updated `flake.lock`.
- **Host configs are `nixosConfigurations`, not standalone files.** A host's `configuration.nix` produces both the `nixosConfigurations.<name>` entry point and a reusable `nixosModules.host<Name>` module.
- **Secrets repo is private.** You cannot read `inputs.nix-secrets`. Work around it: use `lib.mkForce` or `lib.mkDefault` for secrets-derived values in tests, or skip eval of secret-dependent paths.
- **`import-tree` auto-imports every `.nix` file.** Don't create `.nix` files under `modules/` that aren't valid flake-parts modules.

### Where to look
- **Adding a host:** `modules/nixosModules/hosts/_example/`, then `just add-host <name>`
- **Adding a feature:** `modules/nixosModules/features/` (NixOS module), reference in host's `configuration.nix` imports
- **Adding a user program:** `modules/homeManagerModules/` (home-manager module), add to host's `homeModules` list in `modules/home-configurations.nix`
- **Adding a package:** `modules/packages/`, then add to `overlays.nix` additions
- **Changing the editor:** `modules/homeManagerModules/_nixvim-config.nix`
- **Theme colors:** `modules/theme.nix`
- **Network topology:** Host config's `topology.self` block, global nodes in `modules/topology.nix`
- **CI:** `.forgejo/workflows/ci.yml`
- **Hetzner IaC:** `tofu/main.tf`, host `host.tf.json` files

### Gotchas
- Disko configs live in host directories (`disko-config.nix`) and are referenced as `self.diskoConfigurations.host<Name>`.
- Some hosts cross-reference each other's configs (e.g., eta reads epsilon's wireguard IPs and ente domains).
- `nix flake check` can be very slow on first run due to ISO build and VM tests. Use `just check --keep-going` for partial results.
- The ISO build in CI patches `builtins.currentTime` and `configurationRevision` to `mkForce "deterministic"` to get a stable derivation path.
- The `keys/` directory is committed and contains only public material — private keys live in the nix-secrets repo.
