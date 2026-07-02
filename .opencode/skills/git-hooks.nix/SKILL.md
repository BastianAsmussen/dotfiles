---
name: git-hooks.nix
description: Use this skill when the user needs to manage pre-commit hooks that enforce formatting, linting, and static analysis before every commit. Applies when discussing `nixfmt`, `deadnix`, `statix`, `flake-checker`, or hook configuration, even if they don't say "pre-commit" or "git-hooks".
metadata:
  input_rev: 3bbec39bc90eadfa031e6f3b77272f3f60803e39
  input_hash: sha256-U3yTuGBnmXvXoQI3qkpfEDsn9RovQPAjN7ndRco+3u0=
  when_to_use: pre-commit, git hooks, nixfmt, deadnix, statix, flake-checker, check-yaml
---

## Pin check

`grep -A4 '"pre-commit-hooks"' flake.lock | grep narHash`
Expected: `sha256-U3yTuGBnmXvXoQI3qkpfEDsn9RovQPAjN7ndRco+3u0=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. To add a hook: edit `modules/pre-commit.nix` and add an entry to the `hooks` attribute set under `pre-commit.settings.hooks`.
2. Hooks install automatically via `nix develop` — the dev shell injects `inputs.pre-commit-hooks.defaultPackage.${system}.shellHook`.
3. To skip hooks temporarily: set `PRE_COMMIT_HOOKS=0` or use `git commit --no-verify`.

## Gotchas

- The flake input is named `pre-commit-hooks` (not `git-hooks.nix`). All Nix references must use `inputs.pre-commit-hooks`, but the skill directory is `.opencode/skills/git-hooks.nix/`.
- Hooks only fire in the dev shell. If you commit outside `nix develop`, no hooks run.
## Verification

`nix develop --command pre-commit run --all-files 2>&1 | tail -5`
