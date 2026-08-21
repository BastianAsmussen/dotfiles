---
name: nixos-testing
description: Use when writing NixOS configuration tests — eval tests, VM tests, or library unit tests — following the patterns in modules/nixos-tests.nix and modules/tests/.
---

# Writing NixOS Configuration Tests

Tests live in three places:

| Type           | Location                     | Purpose                                  |
|----------------|------------------------------|------------------------------------------|
| Eval tests     | `modules/nixos-tests.nix`    | Assert config values without booting     |
| VM tests       | `modules/nixos-tests.nix`    | Runtime behaviour (booted VMs, x86_64)   |
| Lib tests      | `modules/tests/<topic>/default.nix` | Unit tests for `lib.custom.*`    |

All tests run as flake checks (`nix flake check`).

## Eval Tests

Eval tests use `mkEvalTest` to evaluate NixOS modules and assert on the resulting config:

```nix
{
  perSystem = { pkgs, lib, ... }:
  let
    mkEvalTest = name: modules: assertFn:
      let
        cfg = evalNixos modules;
        ok = assertFn cfg;
      in
      assert lib.assertMsg ok "nixos-eval-${name}: assertion failed";
      pkgs.runCommandLocal "nixos-eval-${name}" { } "touch $out";
  in
  {
    checks = {
      nixos-eval-my-test = mkEvalTest "my-test" [
        self.nixosModules.base
        self.nixosModules.myFeature
        { preferences.user.name = "testuser"; }
      ] (cfg: cfg.services.myService.enable == true);
    };
  };
}
```

### Pattern

Each eval test:
1. Imports the modules under test
2. Optionally overrides preferences for hermetic evaluation (no nix-secrets dependency)
3. Makes assertions on the final `config`

### Hermetic Overrides

The top-level `testUser` definition provides safe defaults:

```nix
testUser = {
  preferences.user = {
    name = "testuser";
    fullName = "Test User";
    email = "test@example.com";
  };
};
```

Override module options directly in the test to keep assertions stable:

```nix
nixos-eval-my-test = mkEvalTest "my-test" [
  self.nixosModules.base
  self.nixosModules.myFeature
  testUser
  { services.myService.port = 9999; }
] (cfg: cfg.services.myService.port == 9999);
```

### What to Test

- Boolean options (`mkEnableOption`): test the default (typically `false`) and the enabled state
- Option defaults: verify correct defaults for all meaningful fields
- Security-sensitive settings: verify SSH, firewall, sandboxing defaults
- Option interactions: verify that sub-options correctly default or combine

## VM Tests

VM tests boot a real NixOS VM and run a Python test script. Only available on `x86_64-linux`:

```nix
checks = lib.optionalAttrs (system == "x86_64-linux") {
  nixos-vm-my-service = pkgs.testers.nixosTest {
    name = "my-service";
    nodes.machine = { lib, ... }: {
      imports = [
        self.nixosModules.base
        self.nixosModules.myFeature
      ];
      preferences.user = {
        name = lib.mkForce "alice";
        fullName = lib.mkForce "Alice Test";
        email = lib.mkForce "alice@test.com";
      };
      preferences.user.authorizedKeyFiles = [ ];
      virtualisation.graphics = false;
    };

    testScript = ''
      machine.wait_for_unit("multi-user.target")
      machine.succeed("my-command --check-something")
    '';
  };
};
```

VM tests are for runtime behaviour (daemon starts, ports listen, services respond). Use them sparingly — they're slow.

## Library Tests

Lib tests (`modules/tests/<topic>/default.nix`) test `lib.custom.*` functions. They're structured as `runCommandLocal` checks:

Example: `modules/tests/math/base.nix` tests `lib.custom.math.*`.

To add a new test, create `modules/tests/<topic>/default.nix` with a `perSystem.checks` entry. The import-tree picks it up automatically.

## Running Tests

```sh
# All checks (eval + VM + flake):
just check

# Specific check:
nix build .#checks.x86_64-linux.nixos-eval-my-test

# Interactive VM test:
nix run .#checks.x86_64-linux.nixos-vm-my-service.driverInteractive
```

The CI (`just check` / `nix flake check`) runs all checks. Pre-commit only runs deadnix/statix/nixfmt — eval and VM tests run in CI.

## Test Coverage Conventions

- Every new feature module should have at least one eval test verifying its enable flag
- Options with defaults should test those defaults
- Security-sensitive modules (SSH, firewall, kernel hardening) need explicit assertions
- VM tests are only for runtime-observable behaviour (services that start, ports that listen, auth that works)
