---
name: lanzaboote
description: Use this skill when the user needs to work with UEFI Secure Boot on NixOS — signing UKIs, managing sbctl keys, or configuring the boot chain integrity. Applies when discussing Secure Boot, `systemd-boot`, or bootloader hardening, even if the user doesn't say "lanzaboote".
metadata:
  input_rev: 7c9a54a7f87b4539ddbd8bda09a8a5f5f9361aa9
  input_hash: sha256-hqijVSEETttmo8Okql9/LG0Ua34hdciKW1a5zzlj8mU=
  when_to_use: lanzaboote, secure boot, uki, sbctl, pkiBundle, systemd-boot, uefi signing, boot chain
---

## Pin check

`grep -A4 '"lanzaboote"' flake.lock | grep narHash`
Expected: `sha256-hqijVSEETttmo8Okql9/LG0Ua34hdciKW1a5zzlj8mU=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. The base module `modules/nixosModules/base/lanzaboote.nix` imports `inputs.lanzaboote.nixosModules.lanzaboote` and configures signing.
2. Import `self.nixosModules.lanzaboote` in epsilon's `configuration.nix:35`.
3. Persist `/var/lib/sbctl` via preservation — without it, the next rebuild can't sign the boot chain.
4. Manage keys with `sbctl` (available in `environment.systemPackages`).

## Gotchas

- Only epsilon uses lanzaboote. Delta uses Limine, eta uses systemd-boot without Secure Boot, and mu has no bootloader. Importing lanzaboote on other hosts will fail.
- `/var/lib/sbctl` must be persisted (line 369-376 in epsilon config). If you forget this, the signing keys are lost on reboot and the boot chain breaks.
## Verification

`nix eval .#nixosConfigurations.epsilon.config.boot.lanzaboote.enable`
