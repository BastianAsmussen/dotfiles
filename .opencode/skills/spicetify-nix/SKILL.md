---
name: spicetify-nix
description: Use this skill when the user needs to customize Spotify declaratively — applying CSS themes, enabling extensions (adblock, betterGenres, copyToClipboard, shuffle), and managing the desktop client's appearance. Applies when discussing Spotify theming or extensions.
metadata:
  input_rev: 9cb27462cfd20edac174353f1e95bc03aa888863
  input_hash: sha256-a7oWSyS7SN81UOqVt481yIEMDsMpaJ7GNdV6Eaz5Yqg=
  when_to_use: spicetify-nix, Spotify customization, declarative Spotify, spicetify
---

## Pin check

`grep -A4 '"spicetify-nix"' flake.lock | grep narHash`
Expected: `sha256-a7oWSyS7SN81UOqVt481yIEMDsMpaJ7GNdV6Eaz5Yqg=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. The home-manager module `modules/homeManagerModules/spicetify.nix` imports `inputs.spicetify-nix.homeManagerModules.default`.
2. Enable spicetify and activate extensions (adblock, betterGenres, copyToClipboard, shuffle) from `inputs.spicetify-nix.legacyPackages`.
3. Included via the desktop profile (`profiles/desktop.nix:10`). Relies on spicetify's marketplace theme — no custom theme colors.

## Gotchas

- Spicetify is explicitly disabled in the noctalia shell (`modules/wrappedPrograms/noctalia.nix:466` sets `spicetify = false`). If you enable it globally and it conflicts with noctalia, check this override.
## Verification

`nix eval .#homeConfigurations.\"bastian@epsilon\".programs.spicetify.enable`
