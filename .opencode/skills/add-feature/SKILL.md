---
name: add-feature
description: Scaffold a new NixOS feature module with enable/disable toggles — self-contained, opt-in system services.
metadata:
  when_to_use: add feature, new feature module, create feature, add nixos module, scaffold feature
---

## Action

1. Create `modules/nixosModules/features/<name>.nix`:
```nix
{
  flake.nixosModules.<name> = { config, lib, pkgs, ... }:
  let cfg = config.<name>; in
  {
    options.<name>.enable = lib.mkEnableOption "Enable <description>";
    config = lib.mkIf cfg.enable { /* service config */ };
  };
}
```

2. Import in host config: `self.nixosModules.<name>`
3. Follow import order: External → hardware/disko → base → Nix → security → features → host-specific
4. Guard all config with `lib.mkIf cfg.enable`

## Gotchas

- Filename determines `flake.nixosModules.<name>` (`ssh.nix` → `self.nixosModules.ssh`)
- Importing does NOT enable — host must set `<name>.enable = true`
- For secrets: import `self.nixosModules.sops`, declare `sops.secrets."..." = {}`
- For options consumed by other modules: namespace under `options.<name>.port`, etc.

## Verification

`nix eval .#nixosModules.<name> --json 2>&1 | head -3 && grep -r "self.nixosModules.<name>" modules/nixosModules/hosts/`
