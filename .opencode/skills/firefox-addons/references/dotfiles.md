# firefox-addons — Reference

## What it is

`gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons` — a large, pre-built set of Firefox extensions as Nix derivations with pinned versions and SRI hashes.

## Why it's in the dotfiles

Reproducible, audit-friendly Firefox extension management without manual XPI downloads.

## How it's wired

- **Overlay:** `modules/overlays.nix:28-29` — applies `inputs.firefox-addons.overlays.default`
- **Standalone home-manager:** `modules/home-configurations.nix:20` — overlay also applied to standalone HM configs
- **Extension binding:** `modules/homeManagerModules/firefox.nix:15` — `addons = pkgs.firefox-addons`
- **Installed extensions:** `modules/homeManagerModules/firefox.nix:41-49` — 7 extensions via schizofox's `extraExtensions`:
  - `gopass-bridge`, `clearurls`, `sponsorblock`, `return-youtube-dislikes`, `"7tv"`, `control-panel-for-youtube`, `control-panel-for-twitter`

## Hosts using it

| Host | How |
|------|-----|
| ε | Via desktop profile → firefox module → schizofox extraExtensions |
| δ | Via desktop profile → firefox module → schizofox extraExtensions |
