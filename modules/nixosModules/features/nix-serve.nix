{inputs, ...}: {
  flake.nixosModules.nix-serve = {
    config,
    pkgs,
    ...
  }: {
    sops.secrets."cache-private-key" = {};

    services.nix-serve = {
      enable = true;

      package = pkgs.nix-serve-ng;
      secretKeyFile = config.sops.secrets."cache-private-key".path;
    };

    nix.settings = {
      secret-key-files = [
        config.sops.secrets."cache-private-key".path
      ];

      trusted-public-keys = [
        inputs.nix-secrets.hosts.lambda.cache-public-key
      ];

      trusted-users = ["builder"];
    };

    # Expose the cache behind nginx with HTTPS.
    nginx.reverseProxies.nix-cache = let
      cfg = config.services.nix-serve;
    in {
      enable = true;

      domain = "internal.asmussen.tech";
      location = "/";
      upstream = "http://${cfg.bindAddress}:${toString cfg.port}";

      ssl = {
        dnsProvider = "cloudflare";
        environmentFile = config.sops.templates."cloudflare-acme-env".path;
      };
    };

    users = {
      users.builder = {
        description = "NixOS Remote Builder";
        isSystemUser = true;
        createHome = false;
        uid = 500;
        group = "builder";
        useDefaultShell = true;

        openssh.authorizedKeys.keys = [
          inputs.nix-secrets.hosts.lambda.builder-ssh-public-key
        ];
      };

      groups.builder.gid = 500;
    };
  };
}
