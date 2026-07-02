---
name: add-module
description: Scaffold a new home-manager module — user program, wired into the appropriate profile (desktop, terminal, bastian).
metadata:
  when_to_use: add home module, add user program, new home-manager module, add hm module
---

## Action

1. Create `modules/homeManagerModules/<name>.nix`:
```nix
{
  flake.homeModules.<name> = { config, lib, pkgs, ... }: {
    programs.<name> = { enable = lib.mkEnableOption "Enable <description>"; };
    config = lib.mkIf config.programs.<name>.enable {
      home.packages = with pkgs; [ ];
    };
  };
}
```

2. Wire into profile in `modules/home-configurations.nix`:
   - GUI app → `modules/homeManagerModules/profiles/desktop.nix`
   - CLI tool → `modules/homeManagerModules/profiles/terminal.nix`
   - Host-specific → `bastianModules.<host>` list
   - Shared package → `modules/homeManagerModules/profiles/bastian.nix` (`home.packages`)

## Gotchas

- New module file does nothing until added to a profile or host module list
- `bastian.nix` uses `home.packages`, terminal/desktop use `self.homeModules.<name>` — wrong profile = no effect
- For stylix-target modules, add `stylix.targets.<name>.enable = false` if doing own theming

## Verification

`ls modules/homeManagerModules/<name>.nix && grep -r "homeModules.<name>" modules/home-configurations.nix modules/homeManagerModules/profiles/`
