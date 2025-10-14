{
  lib,
  config,
  pkgs,
  userInfo,
  ...
}: {
  options.nix.binaryCache = {
    enable = lib.mkEnableOption "Make this machine host a binary cache.";
    domain = lib.mkOption {
      default = "internal.asmussen.tech";
      description = "A DNS record pointing to the binary cache.";
      type = lib.types.str;
    };
  };

  config = let
    cfg = config.nix.binaryCache;
  in
    lib.mkIf config.nix.binaryCache.enable {
      nix.settings = {
        substituters = [
          "https://${cfg.domain}/"
          "https://cache.nixos.org/"
        ];

        trusted-public-keys = [
          "internal.asmussen.tech:FfvMc1N66wWVZQHaRUZl1GJOdpqAUIZcmJ2/g079NJI="
        ];
      };

      services = {
        nix-serve = {
          enable = true;

          package = pkgs.nix-serve-ng;
          secretKeyFile = config.sops.secrets."keys/cache/private".path;
        };

        nginx = {
          enable = true;

          recommendedTlsSettings = true;
          recommendedOptimisation = true;
          recommendedGzipSettings = true;
          recommendedProxySettings = true;

          # Only allow PFS-enabled ciphers with AES-256.
          sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

          virtualHosts."${cfg.domain}" = let
            cfg' = config.services.nix-serve;
          in {
            enableACME = true;
            forceSSL = true;

            locations."/".proxyPass = "http://${cfg'.bindAddress}:${toString cfg'.port}";
          };
        };
      };

      # TLS encryption.
      users.users.nginx.extraGroups = ["acme"];
      security.acme = {
        acceptTerms = true;
        defaults.email = userInfo.email;
      };

      networking.firewall.allowedTCPPorts = with config.services.nginx; [
        defaultHTTPListenPort
        defaultSSLListenPort
      ];

      sops.secrets = {
        "keys/cache/private" = {};
        "keys/cache/public" = {};
      };
    };
}
