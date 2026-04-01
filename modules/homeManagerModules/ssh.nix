{inputs, ...}: {
  flake.homeModules.ssh = {
    programs.ssh = {
      enable = true;

      matchBlocks."home" = {
        hostname = inputs.nix-secrets.user.trusted-host-addr;
        port = 22;
        user = "bastian";
        identitiesOnly = true;
        extraOptions = {
          RemoteForward = "/run/user/1000/gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra";
          StreamLocalBindUnlink = "yes";
        };
      };
    };
  };
}
