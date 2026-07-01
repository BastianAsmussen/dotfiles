---
name: add-feature
description: Use this skill when the user needs to scaffold a new NixOS feature module with enable/disable toggles — adding self-contained, opt-in system services or capabilities. Trigger: "add feature", "new feature module", "create feature for", "add a nixos feature".
metadata:
  when_to_use: add feature, new feature module, create feature, add nixos module, scaffold feature
---

## Action

1. Create `modules/nixosModules/features/<name>.nix`:
   ```nix
   {
     flake.nixosModules.<name> = { config, lib, pkgs, ... }:
     let
       cfg = config.<name>;
     in
     {
       options.<name>.enable = lib.mkEnableOption "Enable <description>";

       config = lib.mkIf cfg.enable {
         # service configuration
       };
     };
   }
   ```

2. Import it in relevant host configs (`modules/nixosModules/hosts/<host>/configuration.nix`):
   ```nix
   self.nixosModules.<name>
   ```

3. Follow the imports ordering convention: External modules → hardware/disko → base → Nix → security → features → host-specific.

4. Use `lib.mkIf cfg.enable` to guard all configuration.

## Gotchas

- The file name under `features/` determines `flake.nixosModules.<name>`. A file named `ssh.nix` becomes `self.nixosModules.ssh`, not `self.nixosModules.<arbitrary-name>`.
- Importing the module in a host's `configuration.nix` does NOT enable it — the host must also set `services.<name>.enable = true` (or wherever the option lives).

## Tips

- For features needing secrets, import `self.nixosModules.sops` and declare `sops.secrets."path"."system/host/<key>" = { }`.
- For features creating options consumed by other modules, define them under a dedicated namespace (`options.<name>.port`, `options.<name>.domain`, etc.).
- For features wrapping external packages, use `self.wrapperModules.<name>` if appropriate.
- See existing features for patterns: `modules/nixosModules/features/`.

## Verification

`nix eval .#nixosModules.<name> --json 2>&1 | head -3 && grep -r "self.nixosModules.<name>" modules/nixosModules/hosts/`
