{inputs, ...}: {
  flake.nixosModules.homeManager = {
    config,
    lib,
    pkgs,
    self,
    ...
  }: let
    inherit (lib) mkOption types mapAttrs;

    cfg = config.home-manager;
  in {
    imports = [
      inputs.home-manager.nixosModules.home-manager
    ];

    options.home-manager.userModules = mkOption {
      type = types.attrsOf (types.listOf types.raw);
      default = {};
      description = "Per-user list of Home Manager modules to import. Each key is a username, each value is a list of Home Manager modules for that user.";
      example = lib.literalExpression ''
        {
          alice = with self.homeModules; [ nixvim git zsh ];
          bob = with self.homeModules; [ git tmux ];
        }
      '';
    };

    config = {
      home-manager = {
        extraSpecialArgs = {inherit inputs pkgs self;};
        useUserPackages = true;
        useGlobalPkgs = true;
        backupFileExtension = "backup";
        users =
          mapAttrs (username: modules: {
            imports = modules;

            home = {
              inherit username;
              homeDirectory = "/home/${username}";
              stateVersion = "25.11";
            };

            programs.home-manager.enable = true;
            systemd.user.startServices = "sd-switch";
          })
          cfg.userModules;
      };
    };
  };
}
