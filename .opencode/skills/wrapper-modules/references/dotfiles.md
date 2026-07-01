# wrapper-modules — Reference

## What it is

`wrapper-modules` (`github:BirdeeHub/nix-wrapper-modules`) is the primary wrapping system for embedding configuration directly into Nix derivations at build time.

## Why it's in the dotfiles

niri and noctalia-shell need their entire configuration baked into the derivation for reproducibility and atomicity.

## How it's wired

- **Input declaration:** `flake.nix:89-92`
- **niri wrapper:** `modules/wrappedPrograms/niri.nix` — `self.wrapperModules.niri`, contains full keybinding table, layout settings, window rules, workspace definitions
  - Package at line 275: `packages.niri = inputs.wrapper-modules.wrappers.niri.wrap { ... }`
- **noctalia-shell wrapper:** `modules/wrappedPrograms/noctalia.nix` — `self.wrapperModules.noctalia-shell`, contains bar widgets, colors (Catppuccin Mocha), app launcher, screen recorder, session menu, system monitor
  - Package at line 511: `packages.noctalia-shell = inputs.wrapper-modules.wrappers.noctalia-shell.wrap { ... }`
- **Host extension:** `modules/nixosModules/features/niri.nix:57` — uses `.extendModules` pattern to add `spawn-at-startup` and `outputs` per host
- **Variant:** `modules/wrappedPrograms/wlr-which-key.nix` — wrapper module using low-level `wrappers` directly

### Architecture
- Wrapper modules are NixOS-style modules with `options` and `config`
- `.wrap` applies all imported wrapper modules and produces a new derivation
- Wrapped derivations are exposed as flake packages via `perSystem.packages.<name>`

## Hosts using it

| Host | How |
|------|-----|
| ε | niri + noctalia-shell wrappers, host-specific niri extensions |
| δ | niri + noctalia-shell wrappers, host-specific niri extensions |
