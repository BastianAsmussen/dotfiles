{inputs, ...}: {
  flake.homeModules.ssh = let
    user = inputs.nix-secrets.user.name;
  in {
    programs.ssh = {
      enable = true;

      enableDefaultConfig = false;
      matchBlocks."epsilon" = {
        inherit user;

        hostname = inputs.nix-secrets.hosts.epsilon.ipv4_address;
        port = 22;
        remoteForwards = [
          {
            bind.address = "/home/${user}/.gnupg/S.gpg-agent.ssh";
            host.address = "/run/user/1000/gnupg/S.gpg-agent.ssh";
          }
        ];

        extraOptions.StreamLocalBindUnlink = "yes";
      };
    };
  };
}
