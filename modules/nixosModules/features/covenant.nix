{ inputs, ... }:
{
  flake.nixosModules.covenant =
    {
      config,
      lib,
      ...
    }:
    {
      options.covenant-extras = {
        domain = lib.mkOption {
          type = lib.types.str;
          default = "covenantofearth.org";
          description = ''
            Domain the Covenant is served on.  It deliberately does not live
            under asmussen.tech: the document stands on its own, and the shared
            wildcard certificate therefore does not cover it.
          '';
        };

        exposePublicly = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Whether to expose the Covenant through an nginx reverse proxy with
            HTTPS.  Off by default because the only host serving it (eta) runs
            nginx in TLS stream-passthrough mode, where a reverse-proxy virtual
            host would fight the stream listener for port 443.  Such a host
            declares its own virtual host on the internal fallback listener and
            routes SNI to it instead.
          '';
        };
      };

      imports = [ inputs.covenant.nixosModules.default ];

      config = {
        services.covenant = {
          enable = true;
          port = lib.mkDefault 8084;
          canonicalURL = "https://${config.covenant-extras.domain}";
        };

        nginx.reverseProxies.covenant = lib.mkIf config.covenant-extras.exposePublicly {
          enable = true;

          inherit (config.covenant-extras) domain;

          location = "/";
          upstream = "http://localhost:${toString config.services.covenant.port}/";
          ssl = {
            dnsProvider = "cloudflare";
            environmentFile = config.sops.templates."cloudflare-acme-env".path;
          };
        };
      };
    };
}
