---
name: preservation
description: Use this skill when the user needs to configure impermanence — tmpfs root that wipes on reboot, with only declared directories surviving via bind-mounts from `/persist`. Applies when discussing what to persist, tmpfs sizing, or initrd bind-mounting.
metadata:
  input_rev: 93416f4614ad2dfed5b0dcf12f27e57d27a5ab11
  input_hash: sha256-mMI9IanU+Xw+pVogD2oT0I2kTmvz2Un/Apc5+CwUpEY=
  when_to_use: preservation, impermanence, tmpfs root, persist, bind-mounts, ephemeral root, wipe on boot
---

## Pin check

`grep -A4 '"preservation"' flake.lock | grep narHash`
Expected: `sha256-mMI9IanU+Xw+pVogD2oT0I2kTmvz2Un/Apc5+CwUpEY=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. The feature module `modules/nixosModules/features/preservation.nix` imports `inputs.preservation.nixosModules.preservation` and defines `persistence.*` options.
2. Enable on a host: set `persistence.enable = true` and declare what to persist (system, userdata, usercache groups).
3. Critical: persist `/etc/ssh` and `/etc/machine-id` with `inInitrd = true` so bind-mounts are active before systemd's `setup-etc`.
4. Never delete `/persist` without careful migration — it holds all durable state.

## Gotchas

- Only epsilon and eta use tmpfs root. Delta has a persistent root and does not import preservation. Asking for preservation config on delta is meaningless.
- `inInitrd = true` is not optional for `/etc/ssh` and `/etc/machine-id`. Without it, SSH host keys vanish at boot and the machine gets a new identity every reboot.
## Verification

`nix eval .#nixosConfigurations.epsilon.config.preservation.preserveAt | jq 'keys'`
