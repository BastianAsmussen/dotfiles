---
name: stylix
description: Use this skill when the user needs system-wide Catppuccin Mocha theming — applying consistent colors, fonts, wallpapers, and cursors across GTK, Qt, GRUB, and terminal programs. Applies when discussing base16Scheme, theming targets, or visual consistency.
metadata:
  input_rev: a6a493119e492e15874caf6f7f8c7e572e64c655
  input_hash: sha256-muBZG4O/agq/ljgHr6c3AsobIWgODAS6vf50xIS7o+Q=
  when_to_use: stylix, Catppuccin, system theme, base16Scheme, stylix.targets
---

## Pin check

`grep -A4 '"stylix"' flake.lock | grep narHash`
Expected: `sha256-muBZG4O/agq/ljgHr6c3AsobIWgODAS6vf50xIS7o+Q=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. The base stylix module `modules/nixosModules/features/stylix.nix` enables stylix, sets `base16Scheme` to catppuccin-mocha, wallpaper, cursors, and fonts.
2. Every host imports both `inputs.stylix.nixosModules.stylix` (upstream) and `self.nixosModules.stylix` (local overrides).
3. For standalone home-manager: `modules/home-configurations.nix:27` imports `inputs.stylix.homeModules.stylix`.
4. Disable stylix for targets that handle their own theming: btop, firefox, nixcord, nixvim, tmux.

## Gotchas

- Btop, firefox, nixcord, nixvim, and tmux all have `stylix.targets.<name>.enable = false`. If a program looks wrong (double-themed or unstyled), check this list — you may need to add or remove a disable line.
## Verification

`nix eval .#nixosConfigurations.epsilon.config.stylix.base16Scheme --raw`
