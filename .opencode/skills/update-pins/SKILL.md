---
name: update-pins
description: After `nix flake update`, sync `input_rev` and `input_hash` metadata in all flake-input skill files to match new `flake.lock`.
metadata:
  when_to_use: update pins, sync skill hashes, after flake update, pin update
---

## Action

After `nix flake update` or `nix flake update <input>`:

1. Read updated `flake.lock` — extract new `narHash` and `rev` for changed input
2. Update skill file at `.opencode/skills/<input-name>/SKILL.md`:
   - `metadata.input_rev` → new rev
   - `metadata.input_hash` → new narHash (hash only, no quotes)
3. If multiple inputs updated, update all affected skill files
4. Verify: `grep -A4 '"<input-name>"' flake.lock | grep narHash`

## Input name → skill folder

First-level inputs in `flake.lock` root node map directly:

| flake.lock input | Skill folder |
|---|---|
| `disko` | `.opencode/skills/disko/` |
| `eh` | `.opencode/skills/eh/` |
| `import-tree` | `.opencode/skills/import-tree/` |
| `lanzaboote` | `.opencode/skills/lanzaboote/` |
| `nix-cachyos-kernel` | `.opencode/skills/nix-cachyos-kernel/` |
| `nix-index-database` | `.opencode/skills/nix-index-database/` |
| `nix-topology` | `.opencode/skills/nix-topology/` |
| `nixcord` | `.opencode/skills/nixcord/` |
| `nixos-hardware` | `.opencode/skills/nixos-hardware/` |
| `nixpkgs` | `.opencode/skills/nixpkgs/` |
| `nixpkgs-stable` | `.opencode/skills/nixpkgs-stable/` |
| `nixvim` | `.opencode/skills/nixvim/` |
| `nix-secrets` | `.opencode/skills/nix-secrets/` |
| `sops-nix` | `.opencode/skills/sops-nix/` |
| `wrapper-modules` | `.opencode/skills/wrapper-modules/` |
| `wrappers` | `.opencode/skills/wrappers/` |

For all 28 flake inputs: read `flake.lock`, find `root.inputs`, update each skill's `input_rev` and `input_hash`.

## Gotchas

- `narHash` in lock is `"sha256-..."` with quotes/comma. Skill `input_hash` needs raw hash, no quotes.
- Some dirs don't match flake input name (e.g. `pre-commit-hooks` → `.opencode/skills/git-hooks.nix/`). Check `Pin check` section in each SKILL.md.

## Verification

`grep "input_hash:" .opencode/skills/<name>/SKILL.md && grep -A4 '"<name>"' flake.lock | grep narHash` — hashes must match.
