{inputs, ...}: {
  flake.nixosModules.website = {config, ...}: {
    imports = [inputs.website.nixosModules.default];

    services.website = {
      enable = true;

      port = 8080;
    };

    nginx.reverseProxies.website = {
      enable = true;

      domain = "internal.asmussen.tech";
      location = "/";
      upstream = "http://localhost:${toString config.services.website.port}";

      ssl = {
        dnsProvider = "cloudflare";
        environmentFile = config.sops.templates."cloudflare-acme-env".path;
      };
    };
  };
}
