{inputs, ...}: {
  flake.homeModules.ssh = {osConfig, ...}: let
    user = osConfig.preferences.user.name;
  in {
    programs.ssh = {
      enable = true;

      matchBlocks."home" = {
        hostname = inputs.nix-secrets.user.trusted-host-addr;
        port = 22;
        inherit user;
        identitiesOnly = true;
        extraOptions = {
          RemoteForward = "/run/user/1000/gnupg/S.gpg-agent.ssh /run/user/1000/gnupg/S.gpg-agent.ssh";
          StreamLocalBindUnlink = "yes";
        };
      };
    };
  };
}
