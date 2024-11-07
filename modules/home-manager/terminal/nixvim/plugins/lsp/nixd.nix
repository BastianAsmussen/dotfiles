{
  lib,
  pkgs,
  userInfo,
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
      flakeRoot = "/home/${userInfo.username}/dotfiles";
    in {
      nixos.expr =
        # nix
        ''
          (builtins.getFlake ${flakeRoot}).nixosConfigurations.${osConfig.networking.hostName}.options
        '';
    };
  };
}
