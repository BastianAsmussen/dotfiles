{ inputs, ... }:
{
  flake.nixosModules.acmeShared =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.acmeShared;
    in
    {
      options.acmeShared = {
        enable = lib.mkEnableOption "Shared Let's Encrypt wildcard cert for asmussen.tech";

        dkRedirects.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Register the legacy .dk redirect domains (dotfiles.dk, fansly.dk,
            tech-college.dk, harvard.dk) pointing at https://asmussen.tech.
            Off by default; enable on hosts that publicly serve nginx.
          '';
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            # Cloudflare DNS-01 environment for the wildcard cert. The nginx
            # feature module also auto-defines these when a proxy or redirect
            # uses cloudflare; mkDefault lets that normal-priority definition
            # win and keeps this one as a fallback for hosts whose nginx setup
            # doesn't trigger the auto-define (e.g. delta, which proxies with
            # client certs rather than ACME).
            sops = {
              secrets."cloudflare-api-token".sopsFile =
                lib.mkDefault "${toString inputs.nix-secrets}/shared.yaml";
              templates."cloudflare-acme-env" = {
                owner = lib.mkDefault "acme";
                content = lib.mkDefault "CF_DNS_API_TOKEN=${config.sops.placeholder."cloudflare-api-token"}";
              };
            };

            users.users.acme.extraGroups = [ "keys" ];

            security.acme = {
              acceptTerms = lib.mkDefault true;
              defaults.email = lib.mkDefault config.preferences.user.email;
              certs."asmussen.tech" = {
                extraDomainNames = [ "*.asmussen.tech" ];
                dnsProvider = "cloudflare";
                environmentFile = config.sops.templates."cloudflare-acme-env".path;
                inherit (config.services.nginx) group;
              };
            };
          }

          (lib.mkIf cfg.dkRedirects.enable {
            nginx.redirects =
              let
                dkRedirect = domain: {
                  inherit domain;
                  enable = true;
                  target = "https://asmussen.tech";
                  ssl = {
                    dnsProvider = "cloudflare";
                    environmentFile = config.sops.templates."cloudflare-acme-env".path;
                  };
                };
              in
              {
                dotfiles-dk = dkRedirect "dotfiles.dk";
                fansly-dk = dkRedirect "fansly.dk";
                tech-college-dk = dkRedirect "tech-college.dk";
                harvard-dk = dkRedirect "harvard.dk";
              };
          })
        ]
      );
    };
}
