---
name: nixos-avf
description: Use this skill when the user needs to run NixOS inside Android's Virtualization Framework on a phone — configuring a VM guest as a WireGuard peer and SSH endpoint without replacing Android. Applies when discussing mu, aarch64, phone Linux, or AVF.
metadata:
  input_rev: d0a62c3f64b45a39570fde31a3a490b214bf19ee
  input_hash: sha256-cJVUBVP3qmRO2HGHqj18ChjOSztyo7eqElQJMRpWXw8=
  when_to_use: nixos-avf, avf, mu, android, phone, aarch64, virtualization framework, mobile nixos
---

## Pin check

`grep -A4 '"nixos-avf"' flake.lock | grep narHash`
Expected: `sha256-cJVUBVP3qmRO2HGHqj18ChjOSztyo7eqElQJMRpWXw8=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. Import `inputs.nixos-avf.nixosModules.avf` in mu's `configuration.nix:29`.
2. Set `avf.defaultUser`, `nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux"`, and topology guest settings.
3. Mu configures it as a lightweight WireGuard peer and SSH endpoint.

## Gotchas

- Mu is `aarch64-linux`, not `x86_64-linux`. Any package that isn't available on aarch64 (or doesn't cross-compile) will fail. This is the only aarch64 host.
- nixos-avf does not replace Android — the host OS remains Android. The NixOS config runs as a VM guest. Bootloader, kernel, and hardware modules (disko, lanzaboote) do not apply.
## Verification

`nix eval .#nixosConfigurations.mu.config.nixpkgs.hostPlatform.system`
