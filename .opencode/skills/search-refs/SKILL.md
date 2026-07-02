---
name: search-refs
description: Find all references to a module, flake input, option, or pattern — tracing imports, usages, and dependencies across the dotfiles.
metadata:
  when_to_use: find references, who uses, where is X used, search module, find imports of, grep for references
---

## Search strategies

```sh
# Module imports
grep -rn "self.nixosModules.<name>\|self.homeModules.<name>" modules/

# Option references
grep -rn "config\.<option-path>" modules/

# Flake input usages
grep -rn "inputs.<input-name>" modules/ hosts/

# Feature enable flags
grep -rn "<feature-name>\.enable" modules/nixosModules/hosts/

# Service declarations
grep -rn "services\.<name>" modules/

# Package references
grep -rn "pkgs\.<name>" modules/

# Disko config references
grep -rn "self\.diskoConfigurations\." modules/

# Secret declarations
grep -rn "sops\.secrets\." modules/
```

## Common patterns

| Looking for | Command |
|---|---|
| Feature imports | `grep -rn "self.nixosModules.<feat>" modules/nixosModules/hosts/` |
| HM module usage | `grep -rn "homeModules.<mod>" modules/home-configurations.nix` |
| Host cross-refs | `grep -rn "nixosConfigurations\.<host>" modules/` |
| Persisted paths | `grep -rn "persist" modules/nixosModules/hosts/<host>/` |
| WireGuard peers | `grep -rn "wireguard\.ips\|wireguard\.peers" modules/` |
| Nginx proxy | `grep -rn "nginx\.reverseProxies\|nginx\.streamProxy" modules/` |

## Gotchas

- Some modules referenced via `self.nixosModules.<name>` (import path), others via `config.services.<name>`. Search both.
- Cross-host refs (e.g. eta → epsilon's WireGuard IPs) via `inputs.nix-secrets.*`, not `self.nixosConfigurations`.

## Output

Per match: file path + line number, 3 lines surrounding context, type (import/option/conditional/dependency).

## Verification

`grep -rc "self.nixosModules.<name>" modules/ && grep -rc "inputs.<input-name>" modules/`
