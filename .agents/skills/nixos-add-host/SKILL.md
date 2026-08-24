---
name: nixos-add-host
description: Use when adding a new NixOS host to the flake. Scaffolds the directory, wires the configuration, and optionally provisions Hetzner infra.
---

# Adding a New Host

## Quick Start

```sh
just add-host <name>
```

This copies `modules/nixosModules/hosts/_example/` and generates `hardware-configuration.nix`. If you don't need the hardware config (e.g. for a VPS), delete it.

## Template Output

After `just add-host zeta`:

```
modules/nixosModules/hosts/zeta/
├── configuration.nix
├── disko-config.nix      # if copied from template
└── hardware-configuration.nix
```

## Wiring the Configuration

### 1. Host Configuration (`configuration.nix`)

The scaffold creates two flake outputs:

```nix
flake.nixosConfigurations.zeta = inputs.nixpkgs.lib.nixosSystem { ... };
flake.nixosModules.hostZeta = { ... }: { ... };
```

Edit the `hostZeta` module to add the imports your machine needs. Organize by category:

```nix
imports = [
  # External modules.
  inputs.disko.nixosModules.disko
  inputs.stylix.nixosModules.stylix

  # Host-specific hardware.
  self.diskoConfigurations.hostZeta

  # Base modules.
  self.nixosModules.base
  self.nixosModules.language
  # ... pick your bootloader: self.nixosModules.lanzaboote / limine / systemdBoot

  # Desktop (skip for headless servers).
  self.nixosModules.greeter
  self.nixosModules.niri
  self.nixosModules.pipewire

  # Nix.
  self.nixosModules.nix
  self.nixosModules.nh

  # Security.
  self.nixosModules.ssh
  self.nixosModules.sops
  # ...

  # Features.
  self.nixosModules.homeManager
  self.nixosModules.topology
  # ...
];
```

Then configure host-specific values:

```nix
networking.hostName = "zeta";
nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";  # or "aarch64-linux"
```

Reference `epsilon/configuration.nix` for a full desktop+server, or `eta/configuration.nix` for a cloud server.

### 2. Home-Manager Modules

Wire the host's home-manager user modules:

```nix
home-manager.userModules.bastian = self.homeModuleSets.zeta;
```

Then define `zeta` in `modules/home-configurations.nix`:

```nix
bastianModules = {
  # ...
  zeta = with self.homeModules; [
    bastian
    terminal     # or: git, gpg, zsh, zoxide, tmux, ...
    # desktop for graphical hosts
  ];
};
```

### 3. Disko Configuration

Every host needs a `disko-config.nix` exported as:

```nix
{ flake.diskoConfigurations.hostZeta = { disko.devices = { ... }; }; }
```

- **Impermanence hosts** (epsilon, eta): root is tmpfs, `/persist` is btrfs
- **Traditional hosts** (delta): root is on the btrfs subvolume directly

See existing hosts for patterns. LUKS hosts use `fido2-device=auto` to enable YubiKey unlock.

### 4. Secrets

Create `hosts/zeta.yaml` in the `nix-secrets` repo. The sops module derives the age key from `/etc/ssh/ssh_host_ed25519_key`, so the host's age public key must be in `.sops.yaml`.

Generate the host age key after first boot:
```sh
just age-host-key
```

Add it to `.sops.yaml` and re-encrypt.

### 5. Topology

Add the host to the network diagram in `modules/topology.nix`:

```nix
nodes.zeta = {
  deviceType = "device";
  name = "zeta";
  hardware.info = "<description>";
  interfaces = { ... };
};
```

And in the host's `configuration.nix`:

```nix
topology.self = {
  hardware.info = "<description>";
  interfaces = { ... };
};
```

## For Hetzner Cloud Hosts

Add a `host.tf.json` in the host directory:

```json
{ "hostname": "zeta", "provider": "hcloud", "server_type": "cax11", "location": "hel1" }
```

The OpenTofu IaC (`tofu/`) globs all `host.tf.json` files and provisions `hcloud_server` resources. For aarch64 hosts, epsilon must be able to cross-compile (binfmt or remote builder).

## Testing

Add eval tests in `modules/nixos-tests.nix` if the module has important invariants. See the `nixos-testing` skill.
