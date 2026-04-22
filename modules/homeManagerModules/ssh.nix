{inputs, ...}: {
  flake.homeModules.ssh = let
    user = inputs.nix-secrets.user.name;
  in {
    home.file.".ssh/known_hosts_static".text = ''
      [${inputs.nix-secrets.hosts.eta.ipv4_address}]:2222 ${inputs.nix-secrets.hosts.eta.initrd-ssh-public-key}
    '';

    programs.ssh = {
      enable = true;

      enableDefaultConfig = false;
      matchBlocks = {
        "eta-initrd" = {
          user = "root";
          hostname = inputs.nix-secrets.hosts.eta.ipv4_address;
          port = 2222;
          extraOptions.UserKnownHostsFile = "~/.ssh/known_hosts ~/.ssh/known_hosts_static";
        };

        "eta" = {
          hostname = "10.10.0.1";
          port = 22;
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
