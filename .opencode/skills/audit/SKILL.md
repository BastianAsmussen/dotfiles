---
name: audit
description: Use this skill when the user requests a full quality check of the dotfiles — formatting, static analysis, dead code detection, flake validation, and skill pin verification. Trigger: "audit", "lint", "format", "check quality", "verify dotfiles", "run checks".
metadata:
  when_to_use: audit, lint, format, check quality, verify dotfiles, run checks, quality check
---

## Action

Run the full quality pipeline in order. Stop if any step fails — fix it before continuing.

1. **Format all Nix files:**
   `just fmt`

2. **Check for dead code (unused variable bindings):**
   `deadnix -o .`
   Or: `just check`

3. **Static analysis (anti-pattern detection):**
   `statix check .`
   Or: `just check`

4. **Flake validation:**
   `just check`
   For faster feedback on specific changes: `nix flake check --keep-going --show-trace`

5. **Skill pin audit (verify all skill hashes match flake.lock):**
   Spot-check a few: `grep -A4 '"disko"' flake.lock | grep narHash`

## Gotchas

- `just check` runs `nix flake check`, which builds the ISO and runs VM tests on x86_64. This can take 30+ minutes on first run. Use `just check --keep-going` for partial results.
- `deadnix` reports unused `let` bindings but may flag bindings that are only used in commented-out code or conditional branches. Don't blindly delete without verifying.

## What each check catches

| Tool | Catches |
|------|---------|
| `nixfmt` | Formatting violations |
| `deadnix` | Unused `let` bindings, dead code |
| `statix` | `with` anti-patterns, inefficient list ops, redundant `rec` |
| `flake-checker` | Outdated/unpinned flake inputs |
| `nix flake check` | Eval errors, broken modules, failed assertions, VM test failures |

## Verification

`just check --keep-going --show-trace`
All git-tracked files must remain unchanged after formatting.
