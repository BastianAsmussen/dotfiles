---
name: egg-mouse-config
description: Use this skill when the user needs to configure an EGG XM2/OP1 gaming mouse on NixOS — adjust CPI, polling rate, lift-off distance, and debounce through a GUI tool. Applies even if the user says "gaming mouse config" or "mouse settings" without naming the tool.
metadata:
  input_rev: a5a977c3e132fe8e7a4e22159b1a44b01e36d173
  input_hash: sha256-7hI1xWeS7Mv35WAp/o/idRMcULVkPDA2eut5R48PcsM=
  when_to_use: egg-mouse-config, EGG mouse, gaming mouse, mouse CPI, polling rate, mouse utilities on NixOS
---

## Pin check

`grep -A4 '"egg-mouse-config"' flake.lock | grep narHash`
Expected: `sha256-7hI1xWeS7Mv35WAp/o/idRMcULVkPDA2eut5R48PcsM=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. Import the module in epsilon's `configuration.nix`: `inputs.egg-mouse-config.nixosModules.default`.
2. Enable it: `programs.egg-mouse-config.enable = true`.
3. This is a single-host concern with a simple enable flag — imported directly in the host config, no wrapper feature module.

## Gotchas

- Only epsilon uses it. Delta has no EGG mouse and eta/mu are headless/AVF — importing the module elsewhere will fail or be irrelevant.
## Verification

`grep -n egg-mouse-config modules/nixosModules/hosts/epsilon/configuration.nix`
