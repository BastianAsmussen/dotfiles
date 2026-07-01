---
name: home-manager
description: Use this skill when the user needs to manage user-level configuration declaratively — programs, dotfiles, services, and profiles that span multiple hosts. Applies when adding user programs, wiring modules into profiles, or setting up standalone home-manager configs.
metadata:
  input_rev: 062581938b4a378a82dfbb294b494808157153a1
  input_hash: sha256-h/xOtrByoA/Ak1lWHn0O1lVZz4qWYbwOSLQ8YSwQO0I=
  when_to_use: home-manager, user environment, homeConfigurations, homeModules
---

## Pin check

`grep -A4 '"home-manager"' flake.lock | grep narHash`
Expected: `sha256-h/xOtrByoA/Ak1lWHn0O1lVZz4qWYbwOSLQ8YSwQO0I=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. Add a home-manager module under `modules/homeManagerModules/<name>.nix`, exporting `flake.homeModules.<name>`.
2. Add the module to the appropriate profile (`terminal`, `desktop`, `bastian`) under `modules/homeManagerModules/profiles/`.
3. For host wiring: each `configuration.nix` sets `home-manager.userModules.bastian = self.homeModuleSets.<host>`.
4. Standalone configs are produced in `modules/home-configurations.nix` via `inputs.home-manager.lib.homeManagerConfiguration`.

## Gotchas

- Modules go under `modules/homeManagerModules/` — not `modules/nixosModules/`. Placing a home-manager module in the NixOS path will fail silently or produce confusing eval errors.
- Profile membership is not automatic. Adding a new module file does nothing until you import it in a profile or host module set.

See [references/dotfiles.md](references/dotfiles.md) for wiring details.

## Verification

`nix eval .#homeConfigurations.\"bastian@epsilon\".activation-script --raw 2>/dev/null | head -c 80`
