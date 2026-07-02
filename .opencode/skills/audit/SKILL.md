---
name: audit
description: Full quality check — formatting, static analysis, dead code, flake validation, and skill pin verification.
metadata:
  when_to_use: audit, lint, format, check quality, verify dotfiles, run checks
---

## Pipeline

Run in order; stop and fix if any step fails.

1. **Format:** `just fmt`
2. **Dead code:** `deadnix -o .`
3. **Static analysis:** `statix check .`
4. **Flake validation:** `just check` (or `just check --keep-going` for skip-on-failure)
5. **Skill pin audit:** spot-check: `grep -A4 '"disko"' flake.lock | grep narHash`

## What each tool catches

| Tool | Catches |
|------|---------|
| `nixfmt` | Formatting violations |
| `deadnix` | Unused `let` bindings, dead code |
| `statix` | `with` anti-patterns, inefficient list ops, redundant `rec` |
| `flake-checker` | Outdated/unpinned flake inputs |
| `nix flake check` | Eval errors, broken modules, failed assertions, VM test failures |

## Gotchas

- `just check` builds ISO + VM tests on x86_64 — 30+ minutes first run. Use `--keep-going` for partial.
- `deadnix` may flag bindings used only in commented-out code/conditionals — verify before deleting.

## Verification

`just check --keep-going --show-trace`

All git-tracked files must remain unchanged after formatting.
