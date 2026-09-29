{ inputs, ... }:
{
  flake.nixosModules.buildHost = {
    nix.settings.trusted-users = [ "builder" ];

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
        ];
      };

      groups.builder.gid = 500;
    };
  };
}
