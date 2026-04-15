{inputs, ...}: {
  flake.nixosModules.nix-serve = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkOption mkIf types;

    cfg = config.nix-serve-extras;
  in {
    options.nix-serve-extras = {
      exposePublicly = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to expose the binary cache through an nginx reverse proxy
          with ACME TLS on cache.asmussen.tech.
        '';
      };

      bindAddress = mkOption {
        type = types.str;
        default = "localhost";
        description = ''
          Address nix-serve listens on.  Override to the host's WireGuard IP
          on peers whose cache must be reachable from remote machines over the
          WireGuard tunnel.
        '';
      };
    };

    config = let
      hostname = config.networking.hostName;
      cacheKeySecret = "hosts/${hostname}/cache-private-key";
    in {
      sops.secrets.${cacheKeySecret} = {};

      services.nix-serve = {
        inherit (cfg) bindAddress;

        enable = true;

        package = pkgs.nix-serve-ng;
        secretKeyFile = config.sops.secrets.${cacheKeySecret}.path;
      };

      nix.settings = {
        secret-key-files = [
          config.sops.secrets.${cacheKeySecret}.path
        ];

        trusted-public-keys = [
          inputs.nix-secrets.hosts.lambda.cache-public-key
          inputs.nix-secrets.hosts.eta.cache-public-key
        ];

        trusted-users = ["builder"];
      };

      # Expose the cache behind nginx with HTTPS only when requested.
      nginx.reverseProxies.nix-cache = mkIf cfg.exposePublicly (let
        serveCfg = config.services.nix-serve;
      in {
        enable = true;

        domain = "cache.asmussen.tech";
        location = "/";
        upstream = "http://${serveCfg.bindAddress}:${toString serveCfg.port}";

        ssl = {
          dnsProvider = "cloudflare";
          environmentFile = config.sops.templates."cloudflare-acme-env".path;
        };
      });

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
            inputs.nix-secrets.hosts.delta.builder-ssh-public-key
            inputs.nix-secrets.hosts.eta.builder-ssh-public-key
          ];
        };

        groups.builder.gid = 500;
      };
    };
  };
}
