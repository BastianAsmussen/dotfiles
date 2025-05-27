{
  lib,
  config,
  pkgs,
  userInfo,
  ...
}: {
  options.nix.binaryCache.enable = lib.mkEnableOption "Make this machine host a binary cache.";

  config = lib.mkIf config.nix.binaryCache.enable {
    nix.settings = {
      substituters = ["https://cache.asmussen.tech"];
      trusted-public-keys = [
        "cache.asmussen.tech:H0C/Z4Hls1uoZb0jj3MsMahWkxZA4Sxn/kw6hyAnnO0="
      ];
    };

    services = {
      nix-serve = {
        enable = true;

        package = pkgs.nix-serve-ng;
        secretKeyFile = "/var/secrets/cache-private-key.pem";
      };

      nginx = {
        enable = true;

        recommendedTlsSettings = true;
        recommendedOptimisation = true;
        recommendedGzipSettings = true;
        recommendedProxySettings = true;

        # Only allow PFS-enabled ciphers with AES-256.
        sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

        virtualHosts."cache.asmussen.tech" = let
          cfg = config.services.nix-serve;
        in {
          enableACME = true;
          forceSSL = true;

          locations."/".proxyPass = "http://${cfg.bindAddress}:${toString cfg.port}";
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
  };
}
