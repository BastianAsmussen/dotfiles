# import-tree — Reference

## What it is

`import-tree` (`github:vic/import-tree`) recursively walks the `modules/` directory and returns every `.nix` file as a flake-parts module function.

## Why it's in the dotfiles

Eliminates manual import lists. Drop a file anywhere under `modules/` and it works. This is the architectural primitive that enables the entire module system.

## How it's wired

- **Input declaration:** `flake.nix:13`
- **Call site:** `flake.nix:111` — `importTree ./modules` passed into `mkFlake`'s module list
- **Exclusions:** `except = [ ./modules/homeManagerModules/_nixvim-config.nix ]` — files that shouldn't be treated as modules

## Critical constraint

Every `.nix` file under `modules/` must be a valid flake-parts module. Placing raw Nix expressions will break the build. The `except` parameter excludes non-module files.
