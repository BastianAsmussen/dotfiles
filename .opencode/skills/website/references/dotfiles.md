# website — Reference

## What it is

Personal Go/HTMX website (`github:BastianAsmussen/website`, asmussen.tech). The upstream flake provides a NixOS module that runs the Go binary as a systemd service.

## Why it's in the dotfiles

The personal site runs on the home infrastructure (epsilon as primary, eta as edge).

## How it's wired

- **Input declaration:** `flake.nix:93-96`
- **Feature module:** `modules/nixosModules/features/website.nix` — imports `inputs.website.nixosModules.default`, wraps with `options.website-extras.exposePublicly` (default `true`)
- **Epsilon:** Runs on port 8083 with full nginx reverse proxy + Cloudflare ACME
- **Eta:** `website-extras.exposePublicly = false` — TLS terminated elsewhere, stream passthrough from eta's nginx to epsilon via WireGuard

## Hosts using it

| Host | How |
|------|-----|
| ε | Primary — full public exposure on 8083 |
| η | Edge — passthrough to epsilon |
