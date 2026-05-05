{inputs, ...}: {
  flake.nixosModules.website = {
    config,
    lib,
    ...
  }: {
    options.website-extras.exposePublicly = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to expose the website through an nginx reverse proxy with HTTPS.
        Set to false when the host handles TLS termination separately (e.g. stream passthrough fallback).
      '';
    };

    imports = [inputs.website.nixosModules.default];

    config = {
      services.website = {
        enable = true;
        port = 8080;
      };

      nginx.reverseProxies.website = lib.mkIf config.website-extras.exposePublicly {
        enable = true;
        domain = "asmussen.tech";
        location = "/";
        upstream = "http://localhost:${toString config.services.website.port}/";
        ssl = {
          dnsProvider = "cloudflare";
          environmentFile = config.sops.templates."cloudflare-acme-env".path;
        };
      };
    };
  };
}
