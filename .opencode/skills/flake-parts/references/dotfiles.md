# flake-parts — Reference

## What it is

`flake-parts` (`github:hercules-ci/flake-parts`) provides `mkFlake`, replacing a raw `flake.nix` output with a modular, option-driven system.

## Why it's in the dotfiles

Every module in this repository plugs into `mkFlake`. import-tree feeds file-discovered modules into flake-parts, which then produces `nixosConfigurations`, `homeConfigurations`, `packages`, `checks`, `devShells`, and `formatter`.

## How it's wired

- **Call site:** `flake.nix:111` — `inputs.flake-parts.lib.mkFlake { inherit inputs; }`
- **Foundational module:** `modules/flake-parts.nix:5` — imports `inputs.flake-parts.flakeModules.modules`, sets up `perSystem`, `systems`, `debug`, re-exports disko and home-manager flakeModules
- **Input declaration:** `flake.nix:9-11`

## Key options

- `perSystem` — system-scoped configuration (packages, dev shells, checks, formatters)
- `systems` — supported architectures (`x86_64-linux`, `aarch64-linux`)
- `debug` — conditional debug builds

## Hosts using it

| Host | How |
|------|-----|
| All | Every host is a `nixosConfiguration` produced by `mkFlake` |
