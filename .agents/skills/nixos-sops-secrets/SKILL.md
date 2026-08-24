---
name: nixos-sops-secrets
description: Use when working with sops-nix secrets. Adding a new secret, wiring it in a module, generating age keys, or updating key registrations.
---

# Managing sops-nix Secrets

Secrets live in a **separate private repository**: `git+ssh://git@codeberg.org/BastianA/nix-secrets.git` (flake input `nix-secrets`).

## Architecture

The flake's sops module (`modules/nixosModules/features/sops.nix`) configures:

- `sops.age.sshKeyPaths`. Derives the age identity from the host's `/etc/ssh/ssh_host_ed25519_key`
- `sops.age.generateKey = true`. Creates the age key at activation time (no separate key file needed)
- Default secrets file: `nix-secrets/hosts/<hostname>.yaml`
- Shared secrets: `nix-secrets/shared.yaml`

With impermanence, the SSH host key is persisted under `/persist/system/etc/ssh/`. The preservation module (`features/preservation.nix`) adds `/persist/system/etc/ssh/ssh_host_ed25519_key` to `sops.age.sshKeyPaths`.

## Adding a New Secret

### 1. Encrypt the secret in nix-secrets

```sh
cd ~/nix-secrets
sops hosts/<hostname>.yaml
```

Add the key-value pair and save.

### 2. Declare it in the module

In a NixOS module:

```nix
sops.secrets."my-feature/api-key" = { };
# Consumed at: config.sops.secrets."my-feature/api-key".path
```

With ownership:

```nix
sops.secrets."my-feature/api-key" = {
  owner = "myuser";
  group = "mygroup";
  mode = "0400";
};
```

In a home-manager module:

```nix
sops.secrets."my-secret" = { };
# Consumed at: config.sops.secrets."my-secret".path
```

### 3. Use the path

```nix
services.myService.apiKeyFile = config.sops.secrets."my-feature/api-key".path;
```

Or in sops templates for derived files:

```nix
sops.templates."my-config" = {
  owner = "root";
  content = ''
    API_KEY=${config.sops.placeholder."my-feature/api-key"}
  '';
};
```

## Key Management

### Host Keys (automatic)

The sops module derives the age key from the SSH host key. No manual setup needed on the host side. To get the public key for `.sops.yaml`:

```sh
just age-host-key
```

### User Keys (manual)

For editing secrets from any machine:

```sh
just age-keygen
```

This creates `~/.config/sops/age/keys.txt`. The home-manager sops module (`modules/homeManagerModules/sops.nix`) already points at this path.

### Updating `.sops.yaml`

Add public keys, then re-encrypt:

```sh
sops updatekeys secrets.yaml
```

The file is in the `nix-secrets` repo, not here.

## Shared Secrets Pattern

Secrets needed by multiple hosts go in `nix-secrets/shared.yaml` with an explicit `sopsFile`:

```nix
sops.secrets."user/bastian/password-hash" = {
  sopsFile = "${toString inputs.nix-secrets}/shared.yaml";
  neededForUsers = true;
};
```

## Impermanence Considerations

When a host uses `persistence.enable = true` (tmpfs root), the following paths are already persisted through the preservation module:

- `/persist/system/etc/ssh`. SSH host keys (required for sops age identity)
- `/persist/system/var/lib/sops-nix`. sops-nix runtime state
- User: `.config/sops`. User age keys

If a secret is written to a path that isn't persisted, it vanishes at reboot. Make sure the consuming service's data directory is listed in `persistence.directories`.

## Common Patterns

**Cloudflare API tokens** (for DNS-01 ACME):

```nix
sops.secrets."cloudflare-api-token" = {
  sopsFile = "${toString inputs.nix-secrets}/shared.yaml";
};

sops.templates."cloudflare-acme-env" = {
  owner = "acme";
  content = "CF_DNS_API_TOKEN=${config.sops.placeholder."cloudflare-api-token"}";
};
```

**mTLS client certificates**:

```nix
sops.secrets."mtls/delta-client-cert" = { owner = "nginx"; };
sops.secrets."mtls/delta-client-key" = { owner = "nginx"; };
```

**WireGuard pre-shared keys**:

```nix
sops.secrets."wireguard/psk-eta-epsilon" = { };
```
