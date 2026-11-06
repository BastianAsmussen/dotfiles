{ inputs, ... }:
{
  flake.nixosModules.acmeShared =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkOption mkIf mkDefault;

      cfg = config.acmeShared;
    in
    {
      options.acmeShared = {
        enable = lib.mkEnableOption "Let's Encrypt DNS-01 defaults for the certificates the caddy module derives";

        dkRedirects = {
          enable = mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to serve the .dk redirect domains pointing at https://asmussen.tech.";
          };

          domains = mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "dotfiles.dk"
              "fansly.dk"
              "tech-college.dk"
              "harvard.dk"
            ];

            description = "Domains redirected to https://asmussen.tech.";
          };
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
                email = mkDefault config.preferences.user.email;
                dnsProvider = mkDefault "cloudflare";
                environmentFile = mkDefault config.sops.templates."cloudflare-acme-env".path;

                # Check renewal every six hours using lego's ARI.
                renewInterval = mkDefault "*-*-* 00/6:00:00";
                renewJitter = mkDefault "1h";

                # lego 5 renamed the DNS propagation wait flag.
                extraLegoFlags = mkDefault [
                  (
                    if lib.versionOlder pkgs.lego.version "5.0.0" then
                      "--dns.propagation-wait=120s"
                    else
                      "--dns.propagation.wait=120s"
                  )
                ];
              };
            };
          }

          (mkIf cfg.dkRedirects.enable {
            services.caddy.virtualHosts = lib.genAttrs cfg.dkRedirects.domains (_: {
              extraConfig = "redir https://asmussen.tech{uri} permanent";
            });
          })
        ]
      );
    };
}
