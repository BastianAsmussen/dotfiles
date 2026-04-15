{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.base = {
    lib,
    config,
    pkgs,
    ...
  }: let
    inherit (lib) mkOption types;

    cfg = config.preferences.user;
  in {
    imports = [
      self.nixosModules.sops
    ];

    options.preferences.user = {
      name = mkOption {
        type = types.str;
        default = inputs.nix-secrets.user.name;
        description = "The user's login name.";
      };

      fullName = mkOption {
        type = types.str;
        default = inputs.nix-secrets.user.full-name;
        description = "The user's full display name.";
      };

      email = mkOption {
        type = types.str;
        default = inputs.nix-secrets.user.email;
        description = "The user's email address.";
      };

      icon = mkOption {
        type = types.path;
        default = ../../../assets/icons/bastian.png;
        description = "Path to the user's account icon image.";
      };

      authorizedKeyFiles = mkOption {
        type = types.listOf types.path;
        default = lib.custom.keys.default.sshPaths;
        description = "SSH authorized key files to install for the user.";
      };
    };

    config = {
      sops.secrets."user/bastian/password-hash".neededForUsers = true;

      programs.zsh.enable = true;

      users = {
        mutableUsers = false;
        users = {
          root.hashedPassword = "*";

          "${cfg.name}" = {
            isNormalUser = true;
            description = cfg.fullName;
            hashedPasswordFile = config.sops.secrets."user/bastian/password-hash".path;
            extraGroups = ["wheel"];
            shell = pkgs.zsh;

            openssh.authorizedKeys.keyFiles = cfg.authorizedKeyFiles;
          };
        };
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
