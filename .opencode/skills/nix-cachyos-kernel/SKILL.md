---
name: nix-cachyos-kernel
description: Use this skill when the user needs the gaming-optimized CachyOS BORE-LTO kernel — for better interactive latency in Proton/Steam titles and ntsync support. Applies when discussing kernel tuning, gaming performance, or scheduler selection, even without saying "cachyos".
metadata:
  input_rev: a24a38a4965219068fc366d311639db613b9e03e
  input_hash: sha256-tfZeKprk8CkiP/Yjnd76QKxrRy2IcezNQ7jVZSaP2/k=
  when_to_use: cachyos, bore-lto, gaming kernel, ntsync, kernel scheduler, linux-cachyos, overlays.pinned
---

## Pin check

`grep -A4 '"nix-cachyos-kernel"' flake.lock | grep narHash`
Expected: `sha256-tfZeKprk8CkiP/Yjnd76QKxrRy2IcezNQ7jVZSaP2/k=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. The gaming module at `modules/nixosModules/features/gaming.nix:12-18` applies `inputs.nix-cachyos-kernel.overlays.pinned` and sets `boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto`.
2. Enable ntsync at line 22 with `boot.kernelModules = [ "ntsync" ]` and add a udev rule at line 109-111 for world-readable `/dev/ntsync`.
3. Epsilon imports `self.nixosModules.gaming` at `configuration.nix:66`. The safeMode specialisation at line 756 forces stock kernel.

## Gotchas

- Only epsilon uses the CachyOS kernel. Delta and eta use the stock kernel. The overlay is only applied in the gaming feature module, not globally.
- The `overlays.pinned` overlay pins kernel versions to the nix-cachyos-kernel flake input. Updating that input updates the kernel — kernel ABI changes may require rebuilding out-of-tree modules.
## Verification

`nix eval .#nixosConfigurations.epsilon.config.boot.kernelPackages.kernel.version`
