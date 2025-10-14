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

      nginx.virtualHosts."internal.asmussen.tech" = {
        enableACME = true;
        forceSSL = true;

        locations."/vault".proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
      };
    };

    sops.secrets.vaultwarden = let
      secretsPath = "${builtins.toString inputs.secrets}/secrets";
    in {
      sopsFile = "${secretsPath}/vaultwarden.env";
      format = "dotenv";
    };
  };
}
