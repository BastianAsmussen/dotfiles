{
  osConfig,
  self,
  lib,
  pkgs,
}: {
  enable = true;

  settings = let
    inherit (osConfig.networking) hostName;

    flake = ''(builtins.getFlake "${self}")'';
    nixos = rec {
      cfg = ''${flake}.nixosConfigurations.${hostName}'';
      opts = ''${cfg}.options'';
    };
  in {
    nixpkgs.expr = ''import ${flake}.inputs.nixpkgs {}'';
    formatting.command = ["${lib.getExe pkgs.alejandra}"];
    options = {
      nixos.expr = nixos.opts;
      lib.expr = ''${nixos.cfg}.lib'';
      home-manager.expr = ''${nixos.opts}.home-manager.users.type.getSubOptions []'';
    };
  };
}
