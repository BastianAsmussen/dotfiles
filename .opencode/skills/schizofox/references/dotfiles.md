# schizofox — Reference

## What it is

`schizofox` (`github:schizofox/schizofox`) provides a security-hardened Firefox with declarative configuration, sandboxing, and extension management.

## Why it's in the dotfiles

Firefox is the primary browser on desktop/laptop. Schizofox provides reproducible, auditable security hardening.

## How it's wired

- **Input declaration:** `flake.nix:65`
- **Module import:** `modules/homeManagerModules/firefox.nix:30-32` — `inputs.schizofox.homeManagerModule`
- **Configuration** (`firefox.nix:35-141`):
  - **Extensions** (37-49): default + 7 version-pinned addons
  - **Search** (85-107): Kagi default, removes Google/Bing/Brave etc.
  - **Bookmarks** (57-82): Proton + VCS folder
  - **Sandbox** (116-128): GPG keyring, gopass store, gpg-agent socket binds
  - **Theme** (130-141): `osConfig.lib.stylix.colors` for Catppuccin-synced coloring
- **Stylix override:** `firefox.nix:34` — disables `stylix.targets.firefox`
- **Launch:** `modules/wrappedPrograms/niri.nix:154` — via `schizofox` command from niri
- **Profile:** `modules/homeManagerModules/profiles/desktop.nix:7` — included in desktop profile

## Hosts using it

| Host | How |
|------|-----|
| ε | Via desktop profile |
| δ | Via desktop profile |
