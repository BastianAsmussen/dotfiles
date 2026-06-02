{ inputs, ... }:
{
  flake.nixosModules.eh = {
    imports = [ inputs.eh.nixosModules.default ];

    programs.eh.enable = true;
  };
}
