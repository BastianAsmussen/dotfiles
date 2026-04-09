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
      secretKeyFile = config.sops.secrets."cache-private-key".path;
    };

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
  };
}
