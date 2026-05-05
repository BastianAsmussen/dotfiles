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

      uid = mkOption {
        type = types.int;
        default = 1000;
        description = "The user's UID (and GID for their primary group).";
      };

      icon = mkOption {
        type = types.path;
        default = ../../../assets/icons/bastian.png;
        description = "Path to the user's account icon image.";
      };

      authorizedKeyFiles = mkOption {
        type = types.listOf types.path;
        default = let
          keys = lib.custom.keys.default;
          # Exclude mu: phone is highest-attack-surface device, should be trust consumer not issuer.
          trustedKeys = lib.filter (k: k.name != "ssh-mu.pub") keys.sshKeys;
        in
          map (k: k.fullPath) trustedKeys;
        description = "SSH authorized key files to install for the user.";
      };
    };

    config = {
      sops.secrets."user/bastian/password-hash" = {
        sopsFile = "${toString inputs.nix-secrets}/shared.yaml";
        neededForUsers = true;
      };

      programs.zsh.enable = true;
      users = {
        mutableUsers = false;

        users = {
          root.hashedPassword = "*";
          "${cfg.name}" = {
            inherit (cfg) uid;

            isNormalUser = true;
            group = cfg.name;
            description = cfg.fullName;
            hashedPasswordFile = config.sops.secrets."user/bastian/password-hash".path;
            extraGroups = ["wheel"];
            shell = pkgs.zsh;
            openssh.authorizedKeys.keyFiles = cfg.authorizedKeyFiles;
          };
        };

        groups."${cfg.name}".gid = cfg.uid;
      };

      # Set the user's icon.
      system.activationScripts.userIcon.text = ''
        mkdir -p /var/lib/AccountsService/{icons,users}

        cp ${cfg.icon} /var/lib/AccountsService/icons/${cfg.name}
        echo -e "[User]\nIcon=/var/lib/AccountsService/icons/${cfg.name}\n" > /var/lib/AccountsService/users/${cfg.name}
      '';
    };
  };
}
