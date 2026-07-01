---
name: update-pins
description: Use this skill after running `nix flake update` — syncs the `input_rev` and `input_hash` metadata in all flake-input skill files to match the new `flake.lock`. Trigger: "update pins", "sync skill hashes", "after flake update", "pin update".
metadata:
  when_to_use: update pins, sync skill hashes, update skill hashes, after flake update, pin update, nix flake update
---

## Action

After running `nix flake update` or `nix flake update <input>`:

1. Read the updated `flake.lock` to extract the new `narHash` and `rev` for the changed input.

2. Update the corresponding skill file at `.opencode/skills/<input-name>/SKILL.md`:
   - Update `metadata.input_rev` with the new rev.
   - Update `metadata.input_hash` with the new narHash.

3. If multiple inputs were updated, update all affected skill files.

4. Run the pin check in each updated skill to confirm:
   `grep -A4 '"<input-name>"' flake.lock | grep narHash`

## Gotchas

- The flake.lock stores the full `"narHash": "sha256-..."` with quotes and trailing comma. The skill's `metadata.input_hash` must contain only the hash string (`sha256-...`) without quotes — the pin check command strips quotes via `grep`.
- Some skill directories don't match the flake input name. For example, `pre-commit-hooks` maps to `.opencode/skills/git-hooks.nix/`. Check the `Pin check` section in each SKILL.md to see the actual flake input name.

## Input name → skill folder mapping

The first-level inputs in the flake.lock `root` node map directly to skill folders:

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
| `nixos-avf` | `.opencode/skills/nixos-avf/` |
| `nixos-hardware` | `.opencode/skills/nixos-hardware/` |
| `nixpkgs` | `.opencode/skills/nixpkgs/` |
| `nixpkgs-stable` | `.opencode/skills/nixpkgs-stable/` |
| `nixvim` | `.opencode/skills/nixvim/` |
| `nix-secrets` | `.opencode/skills/nix-secrets/` |
| `sops-nix` | `.opencode/skills/sops-nix/` |
| `wrapper-modules` | `.opencode/skills/wrapper-modules/` |
| `wrappers` | `.opencode/skills/wrappers/` |
| ... and so on for all 28 flake inputs |

To update all pins after a full `nix flake update`, read `flake.lock`, find the `root.inputs` node, then for each input name update its skill file's `metadata.input_rev` and `metadata.input_hash` from the lock entry's `narHash` and `rev`.

## Verification

`grep "input_hash:" .opencode/skills/<name>/SKILL.md && grep -A4 '"<name>"' flake.lock | grep narHash` — the two hashes must match.
