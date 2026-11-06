{ inputs, ... }:
{
  flake.nixosModules.buildHost =
    { config, ... }:
    {
      # Sign locally-built paths so hosts that never build accept them.
      sops.secrets."hosts/${config.networking.hostName}/cache-private-key" = { };

      nix.settings = {
        trusted-users = [ "builder" ];

        secret-key-files = [
          config.sops.secrets."hosts/${config.networking.hostName}/cache-private-key".path
        ];
      };

      users = {
        users.builder = {
          description = "NixOS Remote Builder";
          isSystemUser = true;
          createHome = false;
          uid = 500;
          group = "builder";
          useDefaultShell = true;
          hashedPassword = "*";
          openssh.authorizedKeys.keys = [
            ''restrict,from="10.10.0.3,fd00:10:10::3" ${inputs.nix-secrets.hosts.delta.builder-ssh-public-key}''
            ''restrict,from="10.10.0.1,fd00:10:10::1" ${inputs.nix-secrets.hosts.eta.builder-ssh-public-key}''
          ];
        };

        groups.builder.gid = 500;
      };
    };
}
