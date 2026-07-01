---
name: add-package
description: Use this skill when the user needs to add a custom Nix package derivation — scaffolding a `perSystem.packages` entry and registering it in the additions overlay so it's available as `pkgs.<name>`. Trigger: "add package", "new derivation", "custom package", "add pkg".
metadata:
  when_to_use: add package, new derivation, custom package, add pkg, scaffold package
---

## Action

1. Create `modules/packages/<name>.nix`:
   ```nix
   {
     perSystem = { pkgs, system, ... }: {
       packages.<name> = pkgs.callPackage ./<name>/default.nix { };
     };
   }
   ```
   Or for simple inline derivations:
   ```nix
   {
     perSystem = { pkgs, ... }: {
       packages.<name> = pkgs.stdenv.mkDerivation {
         pname = "<name>";
         version = "<version>";
         src = pkgs.fetchFromGitHub {
           owner = "<owner>";
           repo = "<repo>";
           rev = "<rev>";
           hash = "<hash>";
         };
       };
     };
   }
   ```

2. Add to the `additions` overlay in `modules/overlays.nix`:
   ```nix
   additions = _: prev: withSystem prev.stdenv.hostPlatform.system (
     { config, ... }:
     {
       <name> = config.packages.<name>;
     }
   );
   ```

3. Optionally expose as a flake app in the same file:
   ```nix
   perSystem.apps.<name> = { type = "app"; program = "${config.packages.<name>}/bin/<binary>"; };
   ```

4. Install via home-manager by adding `pkgs.<name>` to `home.packages` or `environment.systemPackages`.

## Gotchas

- The overlay in `modules/overlays.nix` requires `withSystem` to bridge between `perSystem` (system-scoped) and the overlay (cross-system). Forgetting `withSystem` causes eval errors about `config.packages` being undefined.
- The `additions` overlay maps to `pkgs.<name>`, but only after the overlay processes. Inside the same module file that defines the package, use `config.packages.<name>` — `pkgs.<name>` doesn't exist yet.

## Tips

- Use `pkgs.buildGoModule`, `pkgs.buildRustPackage`, or `pkgs.buildNpmPackage` for language-specific builders.
- For pre-existing nixpkgs packages that need patching, use overrides in `modules/overlays.nix` (modifications overlay) instead of a custom package.

## Verification

`nix build .#<name> && ls result/bin/`
