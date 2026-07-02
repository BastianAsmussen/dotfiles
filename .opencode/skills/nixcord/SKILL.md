---
name: nixcord
description: Use this skill when the user needs declarative Discord with Vencord client mods — configuring themes, plugins, and the Vesktop wrapper. Applies when working on Discord customization, even if the user doesn't say "nixcord".
metadata:
  input_rev: 9027812cc7365c973105091f0a89130474738107
  input_hash: sha256-5n5ZhxoOLPYH+2HRpeXncjGz/6BfA20u4Pq8hSGQk4s=
  when_to_use: nixcord, Discord with Vencord, Vesktop, FlameFlag nixcord
---

## Pin check

`grep -A4 '"nixcord"' flake.lock | grep narHash`
Expected: `sha256-5n5ZhxoOLPYH+2HRpeXncjGz/6BfA20u4Pq8hSGQk4s=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. The home-manager module at `modules/homeManagerModules/nixcord.nix` imports `inputs.nixcord.homeModules.nixcord`.
2. Configure clients (discord, vesktop), theme (Catppuccin Mocha CSS), plugins, and extra config under `programs.nixcord`.
3. Disable `stylix.targets.nixcord` since nixcord applies its own theming — leaving it enabled causes conflicting styles.

## Gotchas

- Stylix must be explicitly disabled for nixcord at `nixcord.nix:33`. If you see double-themed Discord or CSS conflicts, check that `stylix.targets.nixcord.enable = false` is present.
## Verification

`nix eval .#homeConfigurations.\"bastian@epsilon\".programs.nixcord.discord.enable`
