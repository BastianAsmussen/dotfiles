---
name: add-module
description: Use this skill when the user needs to add a new home-manager module — scaffolding a user program, wiring it into the appropriate profile (desktop, terminal, bastian), and ensuring it's properly consumed by hosts. Trigger: "add home module", "add user program", "new home-manager module", "add hm module".
metadata:
  when_to_use: add home module, add user program, new home-manager module, add hm module, scaffold home manager
---

## Action

1. Create `modules/homeManagerModules/<name>.nix`:
   ```nix
   {
     flake.homeModules.<name> = { config, lib, pkgs, ... }: {
       programs.<name> = {
         enable = lib.mkEnableOption "Enable <description>";
       };

       config = lib.mkIf config.programs.<name>.enable {
         home.packages = with pkgs; [ ];
         # additional configuration
       };
     };
   }
   ```

2. Add it to the appropriate profile or host module set in `modules/home-configurations.nix`:
   - GUI app → add to `modules/homeManagerModules/profiles/desktop.nix` imports
   - CLI tool → add to `modules/homeManagerModules/profiles/terminal.nix` imports
   - Host-specific → add inline to `bastianModules.<host>` list
   - All-user shared package → add to `modules/homeManagerModules/profiles/bastian.nix` (`home.packages`)

3. If the module is standalone (not a profile member), reference it in a host:
   ```nix
   bastianModules.epsilon = with self.homeModules; [ ... <name> ... ];
   ```

## Gotchas

- The profile system is additive but not automatic. A new module file does nothing until it's added to a profile or host module list in `modules/home-configurations.nix`.
- `bastian.nix` profile uses `home.packages`, while terminal and desktop profiles use `self.homeModules.<name>`. Adding a module to the wrong profile has no effect.

## Tips

- For modules that configure stylix targets, consider adding `stylix.targets.<name>.enable = false` if the module does its own theming.
- For modules requiring other home-module state, read `config.programs.<dependency>.enable` before enabling related config.

## Verification

`ls modules/homeManagerModules/<name>.nix && grep -r "homeModules.<name>" modules/home-configurations.nix modules/homeManagerModules/profiles/`
