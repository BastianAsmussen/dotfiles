---
name: wrappers
description: Use this skill when the user needs the low-level `wrapModule` primitive for wrapping a single binary with YAML-formatted CLI arguments. Only applies to `wlr-which-key` — prefer `wrapper-modules` for everything else. Trigger when dealing with `wrapModule`, `wlr-which-key` wrapping, or `inputs.wrappers.lib.wrapModule`.
metadata:
  input_rev: ce9122bf06697ade7c5087940e0c280b89dd0208
  input_hash: sha256-pMJOun/oYhXqes+B3khzRDGWuiCNiWJ25+SVW0OwzNY=
  when_to_use: Lassulus wrappers, wrapModule, wlr-which-key wrapper, low-level wrapping
---

## Pin check

`grep -A4 '"wrappers"' flake.lock | grep narHash`
Expected: `sha256-pMJOun/oYhXqes+B3khzRDGWuiCNiWJ25+SVW0OwzNY=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. This is a low-level library. Unless adding a new low-level wrapper like `wlr-which-key`, prefer `wrapper-modules` instead.
2. The only direct use is `modules/wrappedPrograms/wlr-which-key.nix:37` — calls `inputs.wrappers.lib.wrapModule` to define `self.wrapperModules.which-key`.
3. `wrapModule` creates a NixOS-style module with `options` (YAML-formatted settings) and `config` (package + CLI args).

## Gotchas

- `wrappers` and `wrapper-modules` are two separate inputs. `wrappers` provides `wrapModule` (single binary); `wrapper-modules` provides `.wrap` and `.extendModules` (composable modules). Don't confuse them.

See [references/dotfiles.md](references/dotfiles.md) for wiring details.

## Verification

`grep -n "inputs.wrappers" modules/wrappedPrograms/wlr-which-key.nix`
