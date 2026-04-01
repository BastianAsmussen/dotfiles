{inputs, ...}: {
  flake.homeModules.ssh = {osConfig, ...}: {
    programs.ssh = {
      enable = true;

      enableDefaultConfig = false;
      matchBlocks."home" = {
        hostname = inputs.nix-secrets.hosts.lambda.ipv4_address;
        port = 22;
        user = osConfig.preferences.user.name;
        identitiesOnly = true;
        extraOptions = {
          RemoteForward = "/run/user/1000/gnupg/S.gpg-agent.ssh /run/user/1000/gnupg/S.gpg-agent.ssh";
          StreamLocalBindUnlink = "yes";
        };
      };
    };
  };
}
