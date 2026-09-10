# Assemble the diagram from sibling files and each host's topology.self.
{ inputs, ... }:
{
  imports = [ inputs.nix-topology.flakeModule ];

  flake.nixosModules.topology = {
    imports = [ inputs.nix-topology.nixosModules.default ];
  };
}
