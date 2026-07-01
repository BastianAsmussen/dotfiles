# stylix — Reference

## What it is

`stylix` (`github:danth/stylix`) applies Catppuccin Mocha across the entire system — GTK, Qt, GRUB, wallpapers, cursors, and fonts.

## Why it's in the dotfiles

Consistent Catppuccin Mocha theme across all hosts without per-program configuration.

## How it's wired

- **Input declaration:** `flake.nix:51-54`
- **Base module:** `modules/nixosModules/features/stylix.nix:2-51` — `self.nixosModules.stylix`:
  - Line 10: enables stylix
  - Line 11: `base16Scheme = catppuccin-mocha`
  - Line 12: wallpaper `assets/wallpapers/tokyo.png`
  - Lines 14-18: Bibata-Modern-Ice cursors size 32
  - Lines 28-31: JetBrains Mono Nerd Font monospace
  - Lines 33-40: DejaVu sans/serif
  - Lines 43-46: Noto Color Emoji
- **Host imports:** Every host imports both `inputs.stylix.nixosModules.stylix` and `self.nixosModules.stylix`
- **GRUB:** `modules/nixosModules/base/grub.nix:27` — `stylix.targets.grub.useWallpaper = true`
- **Standalone HM:** `modules/home-configurations.nix:27` — `inputs.stylix.homeModules.stylix`
- **Disabled targets:** btop, firefox, nixcord, nixvim, tmux (each handles its own theming)

## Hosts using it

| Host | How |
|------|-----|
| All | Every host imports stylix for system theming |
