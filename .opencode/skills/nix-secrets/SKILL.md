---
name: nix-secrets
description: Use this skill when the user needs to reference secrets or public identity values in the dotfiles — host IPs, WireGuard keys, password hashes, or API tokens. Applies when wiring sops secrets, reading public values from `inputs.nix-secrets.*`, or understanding the private/public repo split.
metadata:
  input_rev: f98ad3fff7b8d63cdd99c76a812554e400e76622
  input_hash: sha256-/3D24OvSbYtEfUuKUJAQmOSkIVm7FK6B+uYWggaI8cA=
  when_to_use: nix-secrets, secrets repo, private flake input, sops secrets
---

## Pin check

`grep -A4 '"nix-secrets"' flake.lock | grep narHash`
Expected: `sha256-/3D24OvSbYtEfUuKUJAQmOSkIVm7FK6B+uYWggaI8cA=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. Reference public values via `inputs.nix-secrets.*` (user identity, host IPs, WireGuard public keys, SSH public keys, Syncthing device IDs).
2. Reference encrypted secrets via `config.sops.secrets."<path>".path` or `config.sops.templates."<name>".path`.
3. **Never hardcode secrets.** The secrets repo is private — use `lib.mkForce`/`lib.mkDefault` for secret-dependent paths in tests.

## Gotchas

- The secrets repo is private and you cannot read `inputs.nix-secrets` without the decryption key. In CI and tests, those paths will fail to evaluate. Use `lib.mkForce` or `lib.mkDefault` to provide test-safe defaults.
- `inputs.nix-secrets` is a flake, not a flat file list. Access values via `inputs.nix-secrets.hosts.<hostname>` and `inputs.nix-secrets.shared`, not by guessing path structures.

See [references/dotfiles.md](references/dotfiles.md) for wiring details.

## Verification

`grep -c 'nix-secrets' flake.nix`
