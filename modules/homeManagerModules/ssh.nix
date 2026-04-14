{inputs, ...}: {
  flake.homeModules.ssh = {
    home.file.".ssh/yubikey.pub".source = ../../keys/ssh-yubikey.pub;

    programs.ssh = {
      enable = true;

      enableDefaultConfig = false;
      matchBlocks."home" = {
        hostname = inputs.nix-secrets.hosts.lambda.ipv4_address;
        port = 22;
        user = inputs.nix-secrets.user.name;
        identityFile = "~/.ssh/yubikey.pub";
        remoteForwards = [
          {
            bind.address = "/run/user/1000/gnupg/S.gpg-agent";
            host.address = "/run/user/1000/gnupg/S.gpg-agent.extra";
          }
        ];

        extraOptions.StreamLocalBindUnlink = "yes";
      };
    };
  };
}
