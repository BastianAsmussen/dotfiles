{
  flake.nixosModules.nix-serve = {
    config,
    pkgs,
    ...
  }: {
    sops.secrets."cache-private-key" = {};

    services.nix-serve = {
      enable = true;

      package = pkgs.nix-serve-ng;
      bindAddress = "0.0.0.0";
      port = 5000;
      secretKeyFile = config.sops.secrets."cache-private-key".path;
    };

    nginx.reverseProxies.nix-cache = let
      cfg = config.services.nix-serve;
    in {
      enable = true;

      domain = "internal.asmussen.tech";
      location = "/nix-cache";
      upstream = "http://${cfg.bindAddress}:${toString cfg.port}";

      ssl = {
        dnsProvider = "cloudflare";
        environmentFile = config.sops.templates."cloudflare-acme-env".path;
      };
    };
  };
}
