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
    nixosOpts = ''${flake}.nixosConfigurations.${hostName}.options'';
  in {
    nixpkgs.expr = ''import ${flake}.inputs.nixpkgs {}'';
    formatting.command = ["${lib.getExe pkgs.alejandra}"];
    options = {
      nixos.expr = nixosOpts;
      home-manager.expr = ''${nixosOpts}.home-manager.users.type.getSubOptions []'';
    };
  };
}
