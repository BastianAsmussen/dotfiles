{
  userInfo,
  pkgs,
  lib,
  ...
}: let
  inherit (userInfo) username fullName icon;
in {
  programs.zsh.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    description = fullName;
    initialPassword = "Password123!";
    extraGroups = ["wheel"];
    shell = pkgs.zsh;

    openssh.authorizedKeys.keyFiles = lib.custom.keys.default.sshPaths;
  };

  # Set the user's icon.
  system.activationScripts.script.text = ''
    mkdir -p /var/lib/AccountsService/{icons,users}

    cp ${icon} /var/lib/AccountsService/icons/${username}
    echo -e "[User]\nIcon=/var/lib/AccountsService/icons/${username}\n" > /var/lib/AccountsService/users/${username}
  '';
}
