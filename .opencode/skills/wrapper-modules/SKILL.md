---
name: wrapper-modules
description: Use this skill when the user needs to embed configuration into Nix derivations at build time — defining wrapper modules for niri, noctalia-shell, or similar compositor/desktop components. Applies when discussing `.wrap`, `.extendModules`, or build-time configuration embedding.
metadata:
  input_rev: 6e7f66fa2cdf4d63162580b438f7fcf87c28a46f
  input_hash: sha256-vAmbArdCyjqpVW+37aCy/PMBOLIqukUXLQuEKLwUhA4=
  when_to_use: wrapper-modules, nix-wrapper-modules, wrapping packages, niri wrapper, noctalia wrapper
---

## Pin check

`grep -A4 '"wrapper-modules"' flake.lock | grep narHash`
Expected: `sha256-vAmbArdCyjqpVW+37aCy/PMBOLIqukUXLQuEKLwUhA4=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. Define wrapper modules under `self.wrapperModules.<name>` as NixOS-style modules with `options` and `config`.
2. Use `inputs.wrapper-modules.wrappers.<name>.wrap { inherit pkgs; imports = [ self.wrapperModules.<name> ]; }` to build the wrapped derivation.
3. Extend per-host via `.extendModules` — pass additional imports at the point of use (e.g., `modules/nixosModules/features/niri.nix:57` adds monitor config and startup spawns).
4. Expose wrapped derivations as flake packages via `perSystem.packages.<name>`.

## Gotchas

- Per-host extensions use `.extendModules`, not a separate `.wrap` call. Adding a second `.wrap` creates a completely independent derivation unrelated to the host config.
- Wrapped derivations must be rebuilt when their config changes. A `nixos-rebuild switch` will NOT rebuild wrapper packages unless the flake inputs changed. Use `nix build .#niri` to force a rebuild.

See [references/dotfiles.md](references/dotfiles.md) for wiring details.

## Verification

`grep -rn wrapper-modules modules/nixosModules/features/niri.nix modules/wrappedPrograms/niri.nix modules/wrappedPrograms/noctalia.nix | head -5`
