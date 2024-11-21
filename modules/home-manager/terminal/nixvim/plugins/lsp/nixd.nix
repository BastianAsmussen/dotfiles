{
  lib,
  pkgs,
  config,
  osConfig,
}: {
  enable = true;

  settings = {
    nixpkgs.expr =
      # nix
      ''
        import <nixpkgs> {}
      '';
    formatting.command = ["${lib.getExe pkgs.alejandra}"];
    options = let
      inherit (osConfig.networking) hostName;

      flakeRoot = "${config.home.homeDirectory}/dotfiles";
    in {
      nixos.expr =
        # nix
        ''
          (builtins.getFlake ${flakeRoot}).nixosConfigurations.${hostName}.options
        '';
      home_manager.expr =
        # nix
        ''
          (builtins.getFlake ${flakeRoot}).homeConfigurations.${hostName}.options
        '';
    };
  };
}
