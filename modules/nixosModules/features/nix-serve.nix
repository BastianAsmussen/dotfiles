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
          with ACME TLS on internal.asmussen.tech.  Set to false on hosts
          that only need to serve the cache to other machines on the
          Tailscale network (e.g. lambda, where eta handles the public
          face).
        '';
      };
    };

    config = {
      sops.secrets."cache-private-key" = {};

      services.nix-serve = {
        enable = true;

        package = pkgs.nix-serve-ng;
        secretKeyFile = config.sops.secrets."cache-private-key".path;

        # Listen on all interfaces so the cache is reachable over
        # Tailscale by other hosts even without the nginx reverse proxy.
        bindAddress = "0.0.0.0";
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

      # Expose the cache behind nginx with HTTPS only when requested.
      nginx.reverseProxies.nix-cache = mkIf cfg.exposePublicly (let
        serveCfg = config.services.nix-serve;
      in {
        enable = true;

        domain = "internal.asmussen.tech";
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
          ];
        };

        groups.builder.gid = 500;
      };
    };
  };
}
