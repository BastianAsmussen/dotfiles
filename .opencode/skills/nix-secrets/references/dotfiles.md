# nix-secrets — Reference

## What it is

A private flake input at `git+ssh://git@codeberg.org/BastianA/nix-secrets.git?shallow=1`. Contains two categories: public values (plaintext YAML at eval time) and encrypted secrets (per-host sops-encrypted YAML decrypted at activation).

## Why it's in the dotfiles

The dotfiles repo must remain public. All sensitive material and host-specific public values live in this private repo.

## How it's wired

- **Flake input:** Declared in `flake.nix`, consumed as `inputs.nix-secrets`
- **Public values:**
  - `modules/nixosModules/base/user.nix:27` — user identity (name, email, fullName)
  - Host IPs and keys from `inputs.nix-secrets.hosts.<hostname>`
  - WireGuard peers, Syncthing devices, Forgejo runner UUID, cache signing keys, initrd SSH keys
- **Encrypted secrets:**
  - `hosts/<hostname>.yaml` — per-host: password hashes, tokens, private keys
  - `shared.yaml` — cross-host shared secrets
  - Decrypted by sops-nix at activation
- **Bootstrap (eta):** `tofu/scripts/extra-files-eta.sh` — manual `sops -d` during initial bootstrap
- **Binary cache exclusion:** `modules/nixosModules/features/nix-serve.nix` — blocks nix-secrets store paths
- **Git maintenance:** Auto-prune and repack configured for `~/nix-secrets`. Zsh `~sec` hash directory shortcut.

## Hosts using it

| Host | How |
|------|-----|
| All | Every host reads public values and encrypted secrets from nix-secrets |
