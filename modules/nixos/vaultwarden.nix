{
  lib,
  config,
  inputs,
  ...
}: {
  options.vaultwarden.enable = lib.mkEnableOption "Enables the Vaultwarden service.";

  config = lib.mkIf config.vaultwarden.enable {
    services = {
      vaultwarden = {
        enable = true;

        backupDir = "/var/lib/vaultwarden/backup";
        environmentFile = config.sops.secrets.vaultwarden.path;
        config = {
          DOMAIN = "https://internal.asmussen.tech/vault";

          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = 8222;
          ROCKET_LOG = "critical";
        };
      };

      nginx.virtualHosts."internal.asmussen.tech" = let
        cfg = config.services.vaultwarden.config;
      in {
        enableACME = true;
        forceSSL = true;

        locations."/vault".proxyPass = "http://${toString cfg.ROCKET_ADDRESS}:${toString cfg.ROCKET_PORT}";
      };
    };

    sops.secrets.vaultwarden = let
      secretsPath = "${toString inputs.secrets}/secrets";
    in {
      sopsFile = "${secretsPath}/vaultwarden.env";
      format = "dotenv";
    };
  };
}
