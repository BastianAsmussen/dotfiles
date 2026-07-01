# spicetify-nix — Reference

## What it is

`spicetify-nix` (`github:Gerg-L/spicetify-nix`) applies custom CSS themes and enables Spotify power-user extensions declaratively.

## Why it's in the dotfiles

Declarative Spotify theming and extensions on desktop/laptop hosts.

## How it's wired

- **Input declaration:** `flake.nix:61-64`
- **Module:** `modules/homeManagerModules/spicetify.nix:3-23` — `self.homeModules.spicetify`, imports `inputs.spicetify-nix.homeManagerModules.default`
- **Extensions:** adblock, betterGenres, copyToClipboard, shuffle from `inputs.spicetify-nix.legacyPackages`
- **Profile:** `modules/homeManagerModules/profiles/desktop.nix:10`
- **Noctalia note:** `modules/wrappedPrograms/noctalia.nix:466` — explicitly disables `spicetify = false`

## Hosts using it

| Host | How |
|------|-----|
| ε | Via desktop profile |
| δ | Via desktop profile |
