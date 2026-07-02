---
name: add-package
description: Scaffold a custom Nix package derivation — `perSystem.packages` entry + additions overlay registration as `pkgs.<name>`.
metadata:
  when_to_use: add package, new derivation, custom package, add pkg, scaffold package
---

## Action

1. Create `modules/packages/<name>.nix`:
```nix
{
  perSystem = { pkgs, ... }: {
    packages.<name> = pkgs.stdenv.mkDerivation {
      pname = "<name>"; version = "<version>";
      src = pkgs.fetchFromGitHub { owner = "<owner>"; repo = "<repo>"; rev = "<rev>"; hash = "<hash>"; };
    };
  };
}
```

2. Add to `additions` overlay in `modules/overlays.nix`:
```nix
additions = _: prev: withSystem prev.stdenv.hostPlatform.system (
  { config, ... }: { <name> = config.packages.<name>; }
);
```

3. Optionally expose as flake app: `perSystem.apps.<name> = { type = "app"; program = "${config.packages.<name>}/bin/<binary>"; };`

## Gotchas

- `withSystem` bridges `perSystem` (system-scoped) to overlay (cross-system) — forgetting it causes eval errors
- Inside the module defining the package: use `config.packages.<name>`, not `pkgs.<name>` (doesn't exist yet)
- Use `pkgs.buildGoModule`, `pkgs.buildRustPackage`, etc. for language-specific builders
- For patching existing nixpkgs packages: use `modifications` overlay, not a custom package

## Verification

`nix build .#<name> && ls result/bin/`
