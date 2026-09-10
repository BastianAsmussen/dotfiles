# nix-topology wiring. The diagram itself is assembled from sibling files and
# from each host's own `topology.self`, so nothing here describes the network.
{ inputs, ... }:
{
  imports = [ inputs.nix-topology.flakeModule ];

  flake.nixosModules.topology = {
    imports = [ inputs.nix-topology.nixosModules.default ];
  };
}
