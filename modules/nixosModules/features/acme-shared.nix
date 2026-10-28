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
      inherit (lib) mkOption mkIf mkDefault;

      cfg = config.acmeShared;
    in
    {
      options.acmeShared = {
        enable = lib.mkEnableOption "Shared Let's Encrypt wildcard cert for asmussen.tech";

        dkRedirects.enable = mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Register the .dk redirect domains (dotfiles.dk, fansly.dk,
            tech-college.dk, harvard.dk) pointing at https://asmussen.tech.
          '';
        };
      };

      config = mkIf cfg.enable (
        lib.mkMerge [
          # Persist ACME certificates across reboots.
          (lib.optionalAttrs (options ? persistence) {
            persistence.directories = [ "/var/lib/acme" ];
          })

          {
            # Cloudflare DNS-01 environment for the wildcard cert.
            sops = {
              secrets."cloudflare-api-token".sopsFile = mkDefault inputs.nix-secrets.sopsFiles."shared.yaml";
              templates."cloudflare-acme-env" = {
                owner = mkDefault "acme";
                content = mkDefault "CF_DNS_API_TOKEN=${config.sops.placeholder."cloudflare-api-token"}";
              };
            };

            users.users.acme.extraGroups = [ "keys" ];
            security.acme = {
              acceptTerms = mkDefault true;
              defaults = {
                # Applies to every cert on the host.
                reloadServices = mkDefault [ "nginx.service" ];
                email = mkDefault config.preferences.user.email;
              };

              certs."asmussen.tech" = {
                inherit (config.services.nginx) group;

                extraDomainNames = [ "*.asmussen.tech" ];
                dnsProvider = "cloudflare";
                environmentFile = config.sops.templates."cloudflare-acme-env".path;
              };
            };
          }

          (mkIf cfg.dkRedirects.enable {
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
