{ inputs, ... }:
{
  flake.homeModules.ssh =
    let
      user = inputs.nix-secrets.user.name;
    in
    {
      home.file.".ssh/known_hosts_static".text = ''
        [${inputs.nix-secrets.hosts.eta.ipv4_address}]:2222 ${inputs.nix-secrets.hosts.eta.initrd-ssh-public-key}
      '';

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
          "eta-initrd" = {
            User = "root";
            HostName = inputs.nix-secrets.hosts.eta.ipv4_address;
            Port = 2222;
            UserKnownHostsFile = "~/.ssh/known_hosts ~/.ssh/known_hosts_static";
          };

          "eta" = {
            HostName = "10.10.0.1";
            Port = 22;
            ForwardAgent = "no";
            RemoteForward = [
              "/home/${user}/.ssh/gpg-agent-forward.ssh /run/user/1000/gnupg/S.gpg-agent.ssh"
              "/home/${user}/.gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra"
            ];

            StreamLocalBindUnlink = "yes";
          };

          "epsilon" = {
            User = user;
            HostName = "10.10.0.2";
            Port = 22;
            ForwardAgent = "no";
            RemoteForward = [
              "/home/${user}/.ssh/gpg-agent-forward.ssh /run/user/1000/gnupg/S.gpg-agent.ssh"
              "/home/${user}/.gnupg/S.gpg-agent /run/user/1000/gnupg/S.gpg-agent.extra"
            ];

            StreamLocalBindUnlink = "yes";
          };
        };
      };
    };
}
