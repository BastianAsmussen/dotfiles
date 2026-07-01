# nixcord — Reference

## What it is

`nixcord` (`github:FlameFlag/nixcord`) provides NixOS and home-manager modules for managing Discord with Vencord client mods declaratively — both the official client and Vesktop wrapper.

## Why it's in the dotfiles

Declarative Discord setup with Vencord mods on desktop/laptop hosts.

## How it's wired

- **Input declaration:** `flake.nix:72-74`
- **Module:** `modules/homeManagerModules/nixcord.nix:3-34` — `self.homeModules.nixcord`, imports `inputs.nixcord.homeModules.nixcord`
- **Configuration** (`nixcord.nix:10-31`): enables discord + vesktop, Catppuccin Mocha CSS theme, 5 plugins (callTimer, dontRoundMyTimestamps, friendsSince, noOnboardingDelay, relationshipNotifier), `IS_MAXIMISED = true`
- **Stylix override:** Line 33 — disables `stylix.targets.nixcord`
- **Profile:** `modules/homeManagerModules/profiles/desktop.nix:8` — included in desktop profile

## Hosts using it

| Host | How |
|------|-----|
| ε | Via desktop profile |
| δ | Via desktop profile |
