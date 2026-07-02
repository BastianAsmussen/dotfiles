---
name: website
description: Use this skill when the user needs to manage the personal Go/HTMX website service — configuring nginx reverse proxying, ACME TLS, or WireGuard passthrough routing. Applies when discussing asmussen.tech, the website systemd service, or multi-host web serving.
metadata:
  input_rev: 9e2576f6b956eac5451a7fecf0b615877614acc4
  input_hash: sha256-jwYteLFDtZwD2IjzzLhVADLOBZoMqFhph86+PURhcHw=
  when_to_use: website, asmussen.tech, Go/HTMX website
---

## Pin check

`grep -A4 '"website"' flake.lock | grep narHash`
Expected: `sha256-jwYteLFDtZwD2IjzzLhVADLOBZoMqFhph86+PURhcHw=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. The feature module `modules/nixosModules/features/website.nix` imports `inputs.website.nixosModules.default`.
2. Set `website-extras.exposePublicly = true` to enable nginx reverse proxy + TLS via ACME with Cloudflare DNS-01. Default exposes publicly.
3. On epsilon: runs on port 8083 with full nginx + ACME. On eta: `exposePublicly = false` (TLS terminated elsewhere, stream passthrough via WireGuard to epsilon).

## Gotchas

- Eta runs the website with `exposePublicly = false`, meaning no local TLS. The stream passthrough in eta's nginx forwards raw TCP to epsilon through the WireGuard tunnel. If the WireGuard link is down, the website is unreachable even though eta is up.
## Verification

`grep -rn website modules/nixosModules/hosts/*/configuration.nix | grep -i website`
