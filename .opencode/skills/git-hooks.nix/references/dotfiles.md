# git-hooks.nix — Reference

## What it is

`pre-commit-hooks` (`github:cachix/git-hooks.nix`) runs automated checks (nixfmt, deadnix, statix, flake-checker, check-yaml) before every commit.

## Why it's in the dotfiles

Prevents commits that would fail CI. Catches formatting, dead code, and structural issues early.

## How it's wired

- **Input declaration:** `flake.nix:78-81` (named `pre-commit-hooks`)
- **Module:** `modules/pre-commit.nix` — imports `inputs.pre-commit-hooks.flakeModule`, configures each hook under `pre-commit.settings.hooks`
- **Auto-install:** `modules/dev-shell.nix:10` — injects `inputs.pre-commit-hooks.defaultPackage.${system}.shellHook` into dev shell

## Configured hooks

| Hook | Description |
|------|-------------|
| `deadnix` | Find dead Nix code |
| `statix` | Nix linting |
| `nixfmt` | Nix formatting |
| `flake-checker` | Flake structure validation |
| `check-yaml` | YAML syntax checks |

## Hosts using it

| Host | How |
|------|-----|
| All | Pre-commit hooks in dev shell, not per-host |
