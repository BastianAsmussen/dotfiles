{
  osConfig,
  config,
  lib,
  pkgs,
  userInfo,
}: {
  enable = true;

  settings = let
    inherit (osConfig.networking) hostName;

    flakeExpr =
      # nix
      ''
        (builtins.getFlake "${config.home.homeDirectory}/dotfiles")
      '';
  in {
    nixpkgs.expr =
      # nix
      ''
        import ${flakeExpr}.inputs.nixpkgs {}
      '';
    formatting.command = ["${lib.getExe pkgs.alejandra}"];
    options = {
      nixos.expr =
        # nix
        ''
          ${flakeExpr}.nixosConfigurations.${hostName}.options
        '';
      home-manager.expr =
        # nix
        ''
          ${flakeExpr}.homeConfigurations."${userInfo.username}@${hostName}".options
        '';
    };
  };
}
