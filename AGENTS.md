# AGENTS.md — dotfiles

NixOS flake for hosts: epsilon (desktop), delta (laptop), eta (VPS), mu (Android), iso (installer).
flake-parts + import-tree auto-discovers `.nix` files under `modules/`. Secrets via sops-nix in private `nix-secrets` repo.

## Conciseness

Answer directly. No preamble. One-word answers are fine. Don't summarize unless asked.
Reference paths/lines, don't paste files (`src/app.ts:42` not full contents).
Read only the minimal context needed to act.
Load skills on demand with `skill`, not preemptively.

## Commands

```sh
just fmt           # nixfmt-tree
just check         # statix, deadnix, flake-checker, eval tests, VM tests
just build HOST=epsilon
just rebuild
just iso
nix develop
nix develop .#infra -c tofu -chdir=tofu plan
```

Pre-commit hooks: `deadnix`, `statix`, `nixfmt`, `flake-checker`, `check-yaml`. Install via `nix develop` (shellHook).
CI (Forgejo) runs `nix flake check --all-systems` on push to master, optionally builds ISO + updates `docs/topology.svg`.

## Component tree

| Path | Purpose |
|------|---------|
| `modules/flake-parts.nix` | Root setup (systems, debug) |
| `modules/checks.nix` | deadnix, statix, flake-checker |
| `modules/formatter.nix` | nixfmt-tree |
| `modules/dev-shell.nix` | Default dev shell |
| `modules/pre-commit.nix` | git-hooks.nix |
| `modules/overlays.nix` | Custom packages, firefox-addons, nixpkgs-stable |
| `modules/nixvim.nix` | Neovim via nixvim, nixd LSP |
| `modules/theme.nix` | Catppuccin Mocha palette (`self.theme`, `self.themeNoHash`) |
| `modules/topology.nix` | Network topology |
| `modules/home-configurations.nix` | Standalone home-manager per host |
| `modules/nixos-tests.nix` | Eval tests + VM tests (x86_64) |
| `modules/tests/` | Pure unit tests via `lib.runTests` |
| `modules/lib.nix` | Custom lib: key mgmt, math, units |
| `modules/nixosModules/base/` | Bootloader, user, monitors, language |
| `modules/nixosModules/features/` | Feature flags: ssh, wireguard, niri, jellyfin... |
| `modules/nixosModules/hosts/` | Per-host nixosConfigurations + diskoConfigurations |
| `modules/homeManagerModules/` | git, zsh, tmux, firefox... |
| `modules/packages/` | Custom derivations |
| `modules/wrappedPrograms/` | niri compositor config embedding |
| `modules/templates/` | C, C#, Go, Haskell, Python, Rust, Zig |

## Key files

| Path | Purpose |
|------|---------|
| `flake.nix` | Entry point, all inputs |
| `flake.lock` | Pinned inputs — never delete |
| `justfile` | Task runner |
| `statix.toml` | statix config |
| `modules/nixosModules/hosts/<host>/` | host: configuration.nix + disko-config.nix + hardware-configuration.nix |
| `modules/nixosModules/hosts/_example/` | Template for `just add-host <name>` |
| `keys/` | Public keys (SSH, Age, GPG, certs) — safe to commit |
| `tofu/` | Hetzner Cloud provisioning + nixos-anywhere |
| `docs/topology.svg` | Auto-generated network diagram |

## Coding conventions

- **Format:** `nixfmt-tree` via `just fmt`
- **Module pattern:** Every `modules/` file is `{ inputs, self, ... }: { flake.<...> = ...; }`
- **Naming:** Host modules → `hostCapitalized` (e.g. `hostEpsilon`). Features → camelCase matching filename.
- **Secrets:** Never hardcode. `inputs.nix-secrets.*` for public values, `config.sops.secrets."<path>".path` for secrets, `config.sops.templates."<name>".path` for templates.
- **Theme:** Use `self.themeNoHash.baseXX` (hash-stripped) for colors.
- **Users:** Declare via `preferences.user`. Avoid hardcoding `/home/bastian`.
- **Host import order:** External modules → hardware/disko → base → Nix → security → features → host-specific.

## Git

- **Branch:** `master` (single-branch)
- **Commits:** [Conventional Commits](https://www.conventionalcommits.org/) — types: `feat`, `fix`, `docs`, `chore`, `refactor`. Scopes: host, feature, or module name.

## Where to look

- Add host: `modules/nixosModules/hosts/_example/`, then `just add-host <name>`
- Add feature: `modules/nixosModules/features/`, import in host's `configuration.nix`
- Add user program: `modules/homeManagerModules/`, add to `homeModules` in `modules/home-configurations.nix`
- Add package: `modules/packages/`, add to `overlays.nix`
- Change editor: `modules/homeManagerModules/_nixvim-config.nix`
- Theme colors: `modules/theme.nix`
- Network topology: host's `topology.self` block, global nodes in `modules/topology.nix`
- CI: `.forgejo/workflows/ci.yml`
- Hetzner IaC: `tofu/main.tf`, host `host.tf.json`

## Gotchas

- Disko configs: in host dirs as `disko-config.nix`, referenced as `self.diskoConfigurations.host<Name>`
- Hosts cross-reference each other (e.g. eta reads epsilon's wireguard IPs)
- `nix flake check` slow on first run (ISO + VM tests). Use `just check --keep-going`
- ISO build patches `builtins.currentTime` and `configurationRevision` to `mkForce "deterministic"`
- `keys/` is public only. Private keys in `nix-secrets` repo.
- `statix`, `deadnix`, lint tools NOT on PATH. Run via pre-commit hooks or `nix flake check`.
- Never delete `flake.lock`. Use `nix flake update` for input changes.
- Secrets repo is private. Use `lib.mkForce`/`lib.mkDefault` for secrets-derived values in tests.
- `import-tree` auto-imports every `.nix` under `modules/`. Don't create non-module `.nix` files there.
