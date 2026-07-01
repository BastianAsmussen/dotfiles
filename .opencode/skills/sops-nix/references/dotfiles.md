# sops-nix — Reference

## What it is

`sops-nix` (`github:Mic92/sops-nix`) is a NixOS module that decrypts sops-encrypted YAML/JSON files at system activation time using Mozilla SOPS with age keys.

## Why it's in the dotfiles

Every host depends on secrets (passwords, tokens, keys, ACME env vars). sops-nix is the sole mechanism for injecting these without plaintext secrets ever touching `/nix/store`.

## How it's wired

- **Input declaration:** `flake.nix:41-44`
- **NixOS module:** `modules/nixosModules/features/sops.nix` — imports upstream, sets `sops.defaultSopsFile`, derives age identity from SSH host key
- **Home-manager:** `modules/homeManagerModules/sops.nix` — upstream HM module for user-level secret access
- **Secret declarations (NixOS):**
  - `modules/nixosModules/base/user.nix:69` — user password hash
  - `modules/nixosModules/features/syncthing.nix:37-43` — Syncthing cert/key
  - `modules/nixosModules/features/nix-serve.nix:48` — cache signing key
  - `modules/nixosModules/features/acmeShared.nix:37` — Cloudflare API token
  - `modules/nixosModules/features/nix.nix:75` — GitHub access token
  - `modules/nixosModules/features/nginx.nix:461` — HTTP basic auth credentials
- **Templates:** `access-tokens.conf`, `cloudflare-acme-env`
- **Persistence:** `/var/lib/sops-nix` preserved across reboots
- **nixvim:** LSP auto-completion of `config.sops.secrets` and `config.sops.templates`
- **justfile:** `age-keygen` and `age-host-key` helpers

## Hosts using it

| Host | How |
|------|-----|
| All | Every host uses sops-nix for its secrets |
