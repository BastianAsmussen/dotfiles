---
name: winapps
description: Use this skill when the user needs to run Windows applications on Linux — configuring a Podman Windows VM with FreeRDP RemoteApp for seamless native windows. Applies when discussing Microsoft Office on NixOS, Windows app integration, or RDP configuration.
metadata:
  input_rev: abc2c3da1a7980a8e87c616f7387bd898aadfeb3
  input_hash: sha256-i7odo7wn2IO2oEeu21U1+hhWW1GNwNnCw1piKZftv0I=
  when_to_use: winapps, Windows VM, dockur, FreeRDP, RemoteApp
---

## Pin check

`grep -A4 '"winapps"' flake.lock | grep narHash`
Expected: `sha256-i7odo7wn2IO2oEeu21U1+hhWW1GNwNnCw1piKZftv0I=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. The feature module `modules/nixosModules/features/winapps.nix` imports the upstream winapps NixOS module.
2. Configure `winapps.*` options: `windowsVersion`, `ramSize`, `cpuCores`, `diskSize`, `rdpScale`, `sharedDir`.
3. Two sops secrets required: `winapps/rdp-user` and `winapps/rdp-pass`.
4. Zsh aliases provided: `win-start`, `win-stop`, `win-restart`, `win-status`.

## Gotchas

- The `sharedDir` option maps a host directory (`~/Windows`) into the Windows VM. Any files created there are owned by the Windows user inside the VM, not by the Linux user. File ownership outside the VM may be confusing.
- The RDP credentials must be declared as sops secrets. Without `winapps/rdp-user` and `winapps/rdp-pass` in the secrets repo, winapps cannot authenticate and will silently fail to connect.
## Verification

`grep -n winapps modules/nixosModules/features/winapps.nix | head -5`
