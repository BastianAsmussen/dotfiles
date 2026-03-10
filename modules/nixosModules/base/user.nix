{
  flake.nixosModules.base = {
    lib,
    config,
    pkgs,
    ...
  }: let
    inherit (lib) mkOption types;

    cfg = config.preferences.user;
  in {
    options.preferences.user = {
      name = mkOption {
        type = types.str;
        default = "bastian";
        description = "The user's login name.";
      };

      fullName = mkOption {
        type = types.str;
        default = "Bastian Asmussen";
        description = "The user's full display name.";
      };

      email = mkOption {
        type = types.str;
        default = "bastian@asmussen.tech";
        description = "The user's email address.";
      };

      icon = mkOption {
        type = types.path;
        default = ../../../assets/icons/bastian.png;
        description = "Path to the user's account icon image.";
      };
    };

    config = {
      programs.zsh.enable = true;

      users.users.${cfg.name} = {
        isNormalUser = true;
        description = cfg.fullName;
        initialPassword = "Password123!";
        extraGroups = ["wheel"];
        shell = pkgs.zsh;

        openssh.authorizedKeys.keyFiles = lib.custom.keys.default.sshPaths;
      };

      # Set the user's icon.
      system.activationScripts.script.text = ''
        mkdir -p /var/lib/AccountsService/{icons,users}

        cp ${cfg.icon} /var/lib/AccountsService/icons/${cfg.name}
        echo -e "[User]\nIcon=/var/lib/AccountsService/icons/${cfg.name}\n" > /var/lib/AccountsService/users/${cfg.name}
      '';
    };
  };
}
