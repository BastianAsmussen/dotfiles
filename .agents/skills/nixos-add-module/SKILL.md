---
name: nixos-add-module
description: Use when adding or modifying a NixOS module or home-manager module in this dotfiles flake. Enforces the flake-parts export pattern, option declaration conventions, and module wiring rules.
---

# Adding or Modifying a NixOS / Home-Manager Module

Every `.nix` file under `modules/` is auto-imported by `import-tree`. The file must expose its module through the flake. Read [AGENTS.md](../../../AGENTS.md) for the full layout and conventions.

## NixOS Module Template

Create `modules/nixosModules/<category>/<name>.nix`:

```nix
{ inputs, self, ... }:
{
  flake.nixosModules.<name> =
    { config, lib, pkgs, ... }:
    let
      inherit (lib)
        mkEnableOption
        mkOption
        mkIf
        types
        ;
      cfg = config.<namespace>;
    in
    {
      options.<namespace> = {
        enable = mkEnableOption "<description>";
        # additional options
      };

      config = mkIf cfg.enable {
        # module implementation
      };
    };
}
```

Category is `base`, `features`, or a new subdirectory if it groups related modules.

## Home-Manager Module Template

Create `modules/homeManagerModules/<name>.nix`:

```nix
{ inputs, self, ... }:
{
  flake.homeModules.<name> =
    { config, lib, pkgs, osConfig ? null, ... }:
    {
      # module implementation
    };
}
```

`osConfig` is `null` when running as standalone home-manager (no NixOS host). Use it to gate host-specific behavior:

```nix
persistence = if osConfig == null then null else osConfig.persistence or null;
```

## Multi-File Modules

For modules with sub-resources (e.g. `goxlr/`):

```
modules/homeManagerModules/<name>/
├── default.nix    # exports flake.homeModules.<name>
├── module.nix     # the actual module body
├── profiles/      # sub-resources
└── icons/         # sub-resources
```

`default.nix` does the flake export and delegates to the real module:

```nix
{ self, ... }:
{
  flake.homeModules.<name> = { ... }: {
    imports = [ self.homeModules.<name>Utility ];
    # ...
  };
}
```

See `modules/homeManagerModules/goxlr/default.nix` for a real example.

## Wiring: Profile Aggregators

After creating the module, import it in the relevant profile:

- `modules/homeManagerModules/profiles/terminal.nix` for terminal tools
- `modules/homeManagerModules/profiles/desktop.nix` for GUI apps
- `modules/homeManagerModules/profiles/bastian.nix` for user-global packages

Then assign it per-host in `modules/home-configurations.nix`:

```nix
bastianModules = {
  epsilon = with self.homeModules; [
    bastian
    myNewModule
    # ...
  ];
};
```

## Option Declaration Style

- Feature modules: use a config namespace matching the feature name (`cfg = config.<feature>`)
- Host-specific tunables: use `preferences.<thing>` namespace
- Always `mkEnableOption` with explicit default override when `default = true`
- All options must have a `description`
- Never leave dead code or unused let-bindings (deadnix check enforces this)

## Secrets in Modules

If the module needs a secret, declare it with `sops.secrets`:

```nix
sops.secrets."my-feature/secret-key" = { };
# Use at: config.sops.secrets."my-feature/secret-key".path
```

The secrets file itself lives in the separate `nix-secrets` repo. Update that repo separately.

## Common Pitfalls

- Forgetting to export via `flake.nixosModules.<name>` or `flake.homeModules.<name>`. The file is imported by import-tree but the module must self-register
- Using `inputs.<thing>` without declaring `inputs` in the function arguments (or `{ inputs, ... }:` at the top level)
- Hardcoding paths. Use `toString inputs.nix-secrets` or `self` references, never absolute paths
- Confusing `pkgs` scope: `perSystem` has `pkgs`, NixOS modules get `pkgs` from the module args, but home-manager modules get it differently. Use `{ pkgs, ... }:` pattern
