---
name: search-refs
description: Use this skill when the user needs to find all references to a module, flake input, option, or pattern across the dotfiles codebase — tracing imports, option usages, and feature dependencies. Trigger: "find references", "who uses", "where is X used", "search module", "find imports of".
metadata:
  when_to_use: find references, who uses, where is X used, search module, find imports of, grep for references
---

## Action

Search across the entire dotfiles codebase using multiple strategies:

1. **Find all imports of a module:**
   `grep -rn "self.nixosModules.<name>\|self.homeModules.<name>" modules/`

2. **Find all option references:**
   `grep -rn "config\.<option-path>" modules/`

3. **Find all flake input usages:**
   `grep -rn "inputs.<input-name>" modules/ hosts/`

4. **Find feature enable flags:**
   `grep -rn "<feature-name>\.enable" modules/nixosModules/hosts/`

5. **Find service declarations:**
   `grep -rn "services\.<name>" modules/`

6. **Find package references:**
   `grep -rn "pkgs\.<name>" modules/`

7. **Find disko config references:**
   `grep -rn "self\.diskoConfigurations\." modules/`

8. **Find secret declarations:**
   `grep -rn "sops\.secrets\." modules/`

## Gotchas

- Some modules are referenced by `self.nixosModules.<name>` (import-path form), others via option paths like `config.services.<name>`. Searching only one form misses references.
- Eta reads epsilon's WireGuard IPs via `inputs.nix-secrets.hosts.epsilon`. Cross-host references won't show up under `self.nixosConfigurations` — search `inputs.nix-secrets` as well.

## Output format

For each match, report:
- File path and line number
- Surrounding context (3 lines before/after)
- Whether it's an import, option reference, conditional, or dependency

## Common search patterns

| What you're looking for | Command |
|---|---|
| Feature module imports | `grep -rn "self.nixosModules.<feat>" modules/nixosModules/hosts/` |
| Home-manager module usage | `grep -rn "homeModules.<mod>" modules/home-configurations.nix` |
| Host cross-references | `grep -rn "nixosConfigurations\.<host>" modules/` |
| Persisted paths | `grep -rn "persist" modules/nixosModules/hosts/<host>/` |
| WireGuard peer config | `grep -rn "wireguard\.ips\|wireguard\.peers" modules/` |
| Nginx proxy config | `grep -rn "nginx\.reverseProxies\|nginx\.streamProxy" modules/` |

## Verification

`grep -rc "self.nixosModules.<name>" modules/ && grep -rc "inputs.<input-name>" modules/`
