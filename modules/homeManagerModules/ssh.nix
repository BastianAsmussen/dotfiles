{inputs, ...}: {
  flake.homeModules.ssh = {config, ...}: {
    programs.ssh = {
      enable = true;

      matchBlocks."gpg-forward" = {
        host = inputs.nix-secrets.user.gpg-forward-host;
        extraOptions = {
          RemoteForward = "/run/user/1000/gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra";
          StreamLocalBindUnlink = "yes";
        };
      };
    };
  };
}
