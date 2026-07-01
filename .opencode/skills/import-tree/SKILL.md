---
name: import-tree
description: Use this skill when the user is surprised that a new `.nix` file was automatically discovered, or needs to understand why files under `modules/` are auto-imported as flake-parts modules. Applies when discussing module discovery, auto-import, or file placement conventions.
metadata:
  input_rev: d321337efd0f23a9eb14a42adb7b2c29313ab274
  input_hash: sha256-Jjuz5CmSkur8KvLDoGa+vylEp+RkQtv4mt/qcMznpH0=
  when_to_use: import-tree, auto-import, file discovery, module loading
---

## Pin check

`grep -A4 '"import-tree"' flake.lock | grep narHash`
Expected: `sha256-Jjuz5CmSkur8KvLDoGa+vylEp+RkQtv4mt/qcMznpH0=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. Place a `.nix` file anywhere under `modules/` — it is automatically discovered and fed to `mkFlake` as a flake-parts module.
2. Every file under `modules/` must be a valid flake-parts module (a function accepting `{ inputs, self, ... }`). Raw Nix expressions break the build.
3. To exclude a file, add it to the `except` list at `flake.nix:111` (e.g., `_nixvim-config.nix`).

## Gotchas

- The `except` parameter takes absolute paths relative to the workspace root. Use `./modules/homeManagerModules/_nixvim-config.nix`, not a bare filename.
- Creating a `.nix` file with a stray syntax error anywhere under `modules/` breaks the entire flake evaluation, not just the module you're working on.

See [references/dotfiles.md](references/dotfiles.md) for wiring details.

## Verification

`grep -c "import-tree" flake.nix && nix eval .#nixosConfigurations.epsilon.config.system.stateVersion --raw 2>/dev/null`
