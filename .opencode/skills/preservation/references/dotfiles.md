# preservation — Reference

## What it is

[preservation](https://github.com/nix-community/preservation) is a NixOS module for impermanence: root is tmpfs (wiped every reboot), only explicitly declared directories survive via bind-mounts from a persistent volume.

## Why it's in the dotfiles

Core security/hygiene pattern: every reboot resets the OS to a known-good state. Rogue config, log bloat, and botched manual edits cannot accumulate.

## How it's wired

- **Input declaration:** `flake.nix:28`
- **Feature module:** `modules/nixosModules/features/preservation.nix`:
  - Line 24: imports `inputs.preservation.nixosModules.preservation`
  - Lines 27-92: `persistence.*` options (master toggle, tmpfs size, persist path, dirs/files/cache)
  - Lines 94-155: config wiring — `/persist` mounted in initrd, sops SSH key path, three preservation groups
  - Lines 123-126, 136-138: `inInitrd = true` for `/etc/ssh` and `/etc/machine-id`
- **Epsilon:** `configuration.nix:57` import, `line 315` enable. Persists: ACME certs, bluetooth, power profiles, Jellyfin, Ente/Postgres, Garage, qBittorrent, *arr, Forgejo runner, ccache, Secure Boot keys, 30+ user dirs
- **Eta:** `configuration.nix:70` import, `line 207-208` enable. Persists: ACME certs, primary-mirror state
- **sops-nix integration:** Lines 97-99 — overrides default age key path to use persisted SSH host key

## Hosts using it

| Host | How |
|------|-----|
| ε | tmpfs root + extensive persistence |
| η | tmpfs root + minimal persistence |
