{
  flake.homeModules.ssh = {
    config,
    lib,
    ...
  }: {
    programs.ssh = {
      enable = true;

      # Forward the local GPG agent's extra socket to remote machines so that
      # GPG signing, encryption and authentication via YubiKey work over SSH.
      matchBlocks."*" = {
        extraOptions = {
          RemoteForward = "/run/user/1000/gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra";
        };
      };
    };
  };
}
