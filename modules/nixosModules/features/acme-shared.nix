{ inputs, ... }:
{
  flake.nixosModules.acmeShared =
    {
      config,
      lib,
      options,
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
          # Persist ACME certificates across reboots.
          (lib.optionalAttrs (options ? persistence) {
            persistence.directories = [ "/var/lib/acme" ];
          })

          {
            # Fallback for hosts where nginx does not define Cloudflare
            # credentials.
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

              # Reload nginx after any certificate renewal, including
              # explicit-path vhosts.
              defaults.reloadServices = lib.mkDefault [ "nginx.service" ];

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
