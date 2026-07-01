---
name: nix-topology
description: Use this skill when the user needs to render or update the network topology diagram — defining nodes, networks, and interfaces that describe the multi-host infrastructure. Applies when discussing network layout, the SVG diagram, or topology declarations.
metadata:
  input_rev: e61876f548e4f301d63640d30ecc1305c05c3986
  input_hash: sha256-Vbkgl7/x8+Gg0gMe94EStfIfNC4bHQIbaZrIAxpuQ/w=
  when_to_use: topology, network diagram, SVG, nix-topology, nodes, networks, interfaces, topology.nix
---

## Pin check

`grep -A4 '"nix-topology"' flake.lock | grep narHash`
Expected: `sha256-Vbkgl7/x8+Gg0gMe94EStfIfNC4bHQIbaZrIAxpuQ/w=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. Define global networks and external nodes in `modules/topology.nix` (imports `inputs.nix-topology.flakeModule`).
2. Declare per-host `topology.self` blocks in each host's `configuration.nix` with interfaces, network connections, and role.
3. Render locally with `just topology`. CI auto-commits updated `docs/topology.svg` on push to master.

## Gotchas

- The CI auto-commits topology changes as `docs: update topology diagram [skip ci]`. If you manually edit `docs/topology.svg`, it will be overwritten on the next CI run. Always regenerate with `just topology` instead.
- External nodes (muPhone, internet, cloudRouter, homeRouter) are defined in `modules/topology.nix`, not in individual host configs.

See [references/dotfiles.md](references/dotfiles.md) for wiring details.

## Verification

`just topology && test -s docs/topology.svg && echo "SVG generated successfully"`
