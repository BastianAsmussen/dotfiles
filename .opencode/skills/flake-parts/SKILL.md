---
name: flake-parts
description: Use this skill when the user needs to understand or modify the flake module system that orchestrates the entire configuration — `mkFlake`, `perSystem`, flake modules. Applies when discussing how modules plug together, system-scoped config, or the flake framework itself.
metadata:
  input_rev: f7c1a2d347e4c52d5fb8d10cb4d94b5884e546fb
  input_hash: sha256-m1Yf0wZ8j1OHjTc2UwHwyQRSnNeSgLJOd7q5Y45hzi4=
  when_to_use: flake-parts, mkFlake, flake modules, perSystem, flake framework
---

## Pin check

`grep -A4 '"flake-parts"' flake.lock | grep narHash`
Expected: `sha256-m1Yf0wZ8j1OHjTc2UwHwyQRSnNeSgLJOd7q5Y45hzi4=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. Call `inputs.flake-parts.lib.mkFlake { inherit inputs; }` with the module list in `flake.nix:111`.
2. Define modules using `perSystem` for system-scoped config (packages, dev shells, checks, formatters), `systems` for supported architectures, `debug` for conditional builds.
3. Register host closures via `flake.nixosConfigurations`, home-manager configs via `flake.homeConfigurations`.
4. The foundational module at `modules/flake-parts.nix:5` imports `inputs.flake-parts.flakeModules.modules` and re-exports flakeModules from disko and home-manager.

## Gotchas

- Every `.nix` file under `modules/` is auto-imported by `import-tree` and fed to `mkFlake`. A raw Nix expression (not a flake-parts module function) will break the entire flake.
- `perSystem` config is scoped to the `systems` list — if a host uses `aarch64-linux` but `systems` omits it, that host's packages won't build.
## Verification

`nix flake show --json 2>/dev/null | jq '.nixosConfigurations | keys'`
