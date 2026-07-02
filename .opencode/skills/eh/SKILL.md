---
name: eh
description: Use this skill when the user needs ergonomic Nix CLI shortcuts with auto-retry — shorter, smarter alternatives to raw `nix` subcommands. Applies when discussing `ns`, `nb`, `nr`, `nd`, or "nix helper tools", even without mentioning "eh".
metadata:
  input_rev: 6351cb76a5256bd71807f244b541a79d5d4d3cd1
  input_hash: sha256-xNmvz86FgLo41jQHMol361/TI7PTa3MYE8Ywnqr7NlA=
  when_to_use: eh, ns, nb, nr, nd, nix shell shortcuts, ergonomic nix CLI
---

## Pin check

`grep -A4 '"eh"' flake.lock | grep narHash`
Expected: `sha256-xNmvz86FgLo41jQHMol361/TI7PTa3MYE8Ywnqr7NlA=`
If different, update `metadata.input_hash` and `metadata.input_rev`.

## Action

1. Enable on a host by importing the feature module at `modules/nixosModules/features/eh.nix`.
2. The module imports `inputs.eh.nixosModules.default` and sets `programs.eh.enable = true`.
3. After rebuild, use `ns`, `nb`, `nr`, `nd` as ergonomic shortcuts for `nix shell/build/run/develop`.

## Gotchas

- The auto-retry only covers `--impure`, `--allow-unfree`, and broken/insecure flags. It does not retry on download failures or eval errors.
## Verification

`grep -rn '"eh"' modules/nixosModules/hosts/epsilon/configuration.nix modules/nixosModules/hosts/delta/configuration.nix`
