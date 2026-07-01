---
name: nix-index-database
description: Use this skill when the user needs command-not-found suggestions or the `,` (comma) runner to try packages without installing them. Applies when discussing shell ergonomics, `nix-locate`, or "command not found" behavior.
metadata:
  input_rev: 3017088b49efd404f78e3b104f553b97e4af786b
  input_hash: sha256-h4WpMr455AfRub0FXBaon6Vcpe0waUyJ4GivIW6oyd4=
  when_to_use: nix-index, command-not-found, comma, nix-locate, nix-index-database
---

## Pin check

`grep -A4 '"nix-index-database"' flake.lock | grep narHash`
Expected: `sha256-h4WpMr455AfRub0FXBaon6Vcpe0waUyJ4GivIW6oyd4=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. Import the NixOS module in the host's `configuration.nix` (`inputs.nix-index-database.nixosModules.nix-index`).
2. Enable at the home-manager level via `modules/homeManagerModules/nix-index.nix` — part of the terminal profile.
3. To test: run a mistyped command or use `, <cmd>` (comma runner).

## Gotchas

- Both the NixOS module AND the home-manager module are required. The NixOS module provides the database; the home-manager module wires it into your shell. Having only one gives silent no-ops.

See [references/dotfiles.md](references/dotfiles.md) for wiring details.

## Verification

`grep -rn nix-index-database modules/nixosModules/hosts/*/configuration.nix | head -5`
