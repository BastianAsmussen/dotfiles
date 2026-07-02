---
name: nixos-hardware
description: Use this skill when the user needs hardware-specific kernel tuning — CPU microcode, power management, SSD TRIM, or firmware packages. Applies when setting up hardware profiles for AMD desktops or Intel laptops, even without saying "nixos-hardware".
metadata:
  input_rev: 875776f0252fcb8618bb948640a0d1f7a5b362be
  input_hash: sha256-/EtnQBcKbsaCAGQ5VRcplrHRkR4ryqyLMpBfkVuG9Xw=
  when_to_use: nixos-hardware, hardware optimization, cpu-amd, cpu-intel, laptop power, ssd trim
---

## Pin check

`grep -A4 '"nixos-hardware"' flake.lock | grep narHash`
Expected: `sha256-/EtnQBcKbsaCAGQ5VRcplrHRkR4ryqyLMpBfkVuG9Xw=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. Import the right hardware modules per host:
   - Epsilon (`configuration.nix:99`): `inputs.nixos-hardware.nixosModules.common-cpu-amd`
   - Delta (`hardware-extra.nix:11-14`): `common-cpu-intel`, `common-pc`, `common-pc-laptop`, `common-pc-ssd`
2. Each module applies kernel modules, kernel parameters, udev rules, and firmware packages automatically.

## Gotchas

- Delta's hardware modules are in `hardware-extra.nix`, not `configuration.nix`. This is a separate file imported by delta's `configuration.nix` — check both files when auditing hardware config.
- The modules are cumulative. Importing both `common-cpu-amd` and `common-cpu-intel` on the same host would set conflicting CPU microcode parameters.
## Verification

`nix eval .#nixosConfigurations.epsilon.config.boot.kernelModules --json | jq '.[] | select(.=="kvm-amd")'`
