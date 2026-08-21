---
name: nixos-impermanence
description: Use when managing the preservation (impermanence) module — declaring persisted state, adding a new host with impermanence, or debugging missing-persist issues.
---

# Persisting State with the Preservation Module

The preservation module (`modules/nixosModules/features/preservation.nix`) implements a tmpfs-on-root setup using [nix-community/preservation](https://github.com/nix-community/preservation). Root is a tmpfs wiped every boot; all persistent state is bind-mounted from `/persist`.

## Which Hosts Use Impermanence

| Host    | Impermanence | Details                                           |
|---------|--------------|---------------------------------------------------|
| epsilon | yes          | tmpfs root (4G), `/persist` on btrfs, `/srv/media` + `/srv/arctic-vault` separate |
| eta     | yes          | tmpfs root (2G), `/persist` on btrfs/LUKS         |
| delta   | no           | Traditional root on btrfs                          |

## Adding Persisted State

Edit the host's `configuration.nix`:

```nix
persistence = {
  enable = true;

  # System directories (under /persist/system).
  directories = [
    "/var/lib/acme"
    { directory = "/var/lib/myService"; user = "myuser"; group = "mygroup"; }
  ];

  # System directories with explicit mode (key = path, value = mode).
  directoriesWithMode = {
    "/var/lib/private" = "0700";
    "/var/lib/sbctl" = "0700";   # Secure Boot keys must survive reboot
  };

  # System files (optional: symlink instead of bind-mount).
  files = [
    { file = "/var/lib/systemd/random-seed"; how = "symlink"; }
  ];

  # Per-user state (relative to ~, stored under /persist/userdata).
  user = {
    directories = [
      "Documents"
      ".config/sops"      # VERY important — age keys
      ".mozilla"
      ".local/share/nvim"
    ];

    directoriesWithMode = {
      ".gnupg" = "0700";
    };

    # User cache (stored under /persist/usercache — rebuildable).
    cache.directories = [
      ".cache/direnv"
    ];

    cache.files = [ ];
  };
};
```

## System-Wide Persisted Paths

The module always persists (by default, no host config needed):

- `/etc/ssh` — SSH host keys (also set `inInitrd = true` for fresh installs)
- `/etc/machine-id` — stable machine ID
- `/var/log`
- `/var/lib/nixos`
- `/var/lib/systemd/timers`
- `/var/lib/sops-nix`

These are declared in the module's `preservation.preserveAt` block.

## Critical Persistence Entries

These are non-obvious but required:

- `/var/lib/sbctl` — **Lanzaboote Secure Boot keys** (epsilon). Without this, sbctl keys vanish at reboot and the next rebuild cannot sign the boot chain → unbootable machine.
- `.config/sops/age` — **User age keys**. Without this, `gopass` and `sops` can't decrypt anything after a reboot.
- `/var/lib/acme` — **Let's Encrypt certificates**. They regenerate but at the cost of hitting rate limits.

## Adding Impermanence to a New Host

1. Use a disko config with tmpfs root:
   ```nix
   nodev."/" = {
     fsType = "tmpfs";
     mountOptions = [ "size=4G" "mode=755" ];
   };
   ```

2. Create a `/persist` subvolume on the btrfs pool.

3. Set `persistence.enable = true` in the host config and declare the directories.

## Common Pitfalls

- **Forgotten state**: when adding a new service, ensure its data directory is in `persistence.directories`. After the first reboot with a fresh tmpfs, missing state means the service starts as a clean install every time.
- **inInitrd**: freshly-installed hosts with tmpfs root need `/etc/ssh` persisted in initrd (the module does this by default) or `sshd` starts with no config on first boot.
- **sops age key path**: with impermanence, the preservation module overrides `sops.age.sshKeyPaths` to point at `/persist/system/etc/ssh/ssh_host_ed25519_key`, not `/etc/ssh/...`. This is automatic — just make sure the host imports the preservation module.
- **claude-code persistence**: the claude-code module (`modules/homeManagerModules/claude-code/default.nix`) manages its own persistence symlinks independently when `osConfig.persistence.enable == true` — no manual setup needed.
