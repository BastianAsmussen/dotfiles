---
name: schizofox
description: Use this skill when the user needs to manage a security-hardened, declarative Firefox — configuring sandboxing, extension management, search engine restrictions, and Catppuccin-synced theming. Applies when discussing browser hardening or Firefox configuration.
metadata:
  input_rev: 0222d835f7f594f455afb8cc3a0a8ef7460bdc80
  input_hash: sha256-QipoAi5e1hQDkacT3G2uYy5lAlMZjvvE92npIUokYq4=
  when_to_use: schizofox, hardened Firefox, Firefox sandbox, declarative Firefox
---

## Pin check

`grep -A4 '"schizofox"' flake.lock | grep narHash`
Expected: `sha256-QipoAi5e1hQDkacT3G2uYy5lAlMZjvvE92npIUokYq4=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. The firefox home-manager module at `modules/homeManagerModules/firefox.nix:30-32` imports `inputs.schizofox.homeManagerModule`.
2. Configure at lines 35-141 under `programs.schizofox`: extensions (7 version-pinned addons), search engines (Kagi default), bookmarks, sandboxing (GPG/gopass binds), and theming.
3. Disable `stylix.targets.firefox` at line 34 — schizofox handles its own theming via stylix color extraction.

## Gotchas

- The sandbox binds for GPG keyring and gopass store are read-write inside Firefox. If these bind paths are wrong, GPG operations inside Firefox (like gopass-bridge auto-fill) will silently fail rather than show an error.
- Search engines are configured at `firefox.nix:85-107` and explicitly remove Google, Bing, Brave, DuckDuckGo, and others. Adding a search engine in Firefox preferences will be wiped on rebuild.

See [references/dotfiles.md](references/dotfiles.md) for wiring details.

## Verification

`nix eval .#homeConfigurations.\"bastian@epsilon\".programs.schizofox.enable`
