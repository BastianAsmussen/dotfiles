{inputs, ...}: {
  flake.homeModules.ssh = let
    user = inputs.nix-secrets.user.name;
  in {
    programs.ssh = {
      enable = true;

      enableDefaultConfig = false;
      matchBlocks = {
        "eta" = {
          inherit user;

          hostname = inputs.nix-secrets.hosts.eta.ipv4_address;
          port = 22;
          forwardAgent = true;
          remoteForwards = [
            {
              bind.address = "/home/${user}/.gnupg/S.gpg-agent.ssh";
              host.address = "/run/user/1000/gnupg/S.gpg-agent.ssh";
            }
          ];

          extraOptions.StreamLocalBindUnlink = "yes";
        };

        "epsilon" = {
          inherit user;

          hostname = "10.10.0.2";
          port = 22;
          proxyJump = "eta";
          forwardAgent = true;
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
  };
}
