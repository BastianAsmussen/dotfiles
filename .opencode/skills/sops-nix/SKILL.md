---
name: sops-nix
description: Use this skill when the user needs to decrypt secrets at NixOS activation time — declaring sops-encrypted values, wiring age identities from SSH host keys, or creating sops templates. Applies when discussing secrets, password hashes, tokens, or ACME environment variables, even without saying "sops".
metadata:
  input_rev: 56b24064fdcaedca53553b1a6d607fd23b613a24
  input_hash: sha256-478kKQBvK6SYTOdN2h9jhKJv94nbXRbFMfuL1WshErg=
  when_to_use: sops-nix, sops, secrets, age encryption, config.sops.secrets, sops.templates
---

## Pin check

`grep -A4 '"sops-nix"' flake.lock | grep narHash`
Expected: `sha256-478kKQBvK6SYTOdN2h9jhKJv94nbXRbFMfuL1WshErg=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. The feature module `modules/nixosModules/features/sops.nix` imports the upstream sops-nix NixOS module and sets `sops.defaultSopsFile` + age identity from SSH host key.
2. Declare a secret with `config.sops.secrets."<path>"` — access its path via `.path` at runtime.
3. For templated configs, use `config.sops.templates."<name>"` with sops placeholders.
4. For home-manager: `modules/homeManagerModules/sops.nix` imports the upstream HM module.

## Gotchas

- The age identity is derived from the host's SSH host key (`/etc/ssh/ssh_host_ed25519_key`). If the host key is not persisted (tmpfs root hosts without `inInitrd = true`), sops decryption fails on reboot because the identity changes.
- sops-nix decrypts at activation time, not eval time. Secret values are available via `.path` (a file path), not as Nix string values. Never try to embed a secret directly in a Nix string.

See [references/dotfiles.md](references/dotfiles.md) for wiring details.

## Verification

`nix eval .#nixosConfigurations.epsilon.config.sops.defaultSopsFile --raw`
