# nix-topology — Reference

## What it is

[nix-topology](https://github.com/oddlama/nix-topology) generates network topology diagrams as SVGs directly from NixOS module declarations. It extracts `topology.self` blocks and `topology.nodes` definitions.

## Why it's in the dotfiles

Visual documentation of the multi-host network layout — home LAN, Hetzner cloud, Android phone, and external nodes.

## How it's wired

- **Input declaration:** `flake.nix:19-21`
- **Global topology:** `modules/topology.nix` — imports `inputs.nix-topology.flakeModule`, defines `home` (192.168.1.0/24) and `cloud` (10.0.0.0/24) networks, external nodes (muPhone, internet, cloudRouter, homeRouter)
- **Per-host `topology.self` blocks:**
  | Host | File | Line |
  |------|------|------|
  | ε | `configuration.nix` | 103 |
  | δ | `configuration.nix` | 81 |
  | η | `configuration.nix` | 141 |
  | μ | `configuration.nix` | 48 |
- **Build:** `just topology` renders SVG locally
- **CI:** `.forgejo/workflows/ci.yml` — auto-commits `docs/topology.svg` as `docs: update topology diagram [skip ci]`
- **Custom icons:** Syncthing, Ente, Android device icons

## Hosts using it

| Host | How |
|------|-----|
| ε | `topology.self` block in host config |
| δ | `topology.self` block in host config |
| η | `topology.self` block in host config |
| μ | `topology.self` block in host config |
