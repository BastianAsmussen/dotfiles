{
  flake.nixosModules.jellyfin = {
    config,
    lib,
    pkgs,
    ...
  }: let
    user = config.preferences.user.name;
    cfg = config.jellyfin;
    pfxPath = "/var/lib/jellyfin/cert.pfx";
    networkXml = "/var/lib/jellyfin/config/network.xml";
    httpsPort = toString cfg.https.listenPort;
    networkXmlTemplate = pkgs.writeText "jellyfin-network.xml" ''
      <?xml version="1.0" encoding="utf-8"?>
      <NetworkConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <EnableHttps>true</EnableHttps>
        <HttpsPort>${httpsPort}</HttpsPort>
        <CertificatePath>${pfxPath}</CertificatePath>
        <CertificatePassword></CertificatePassword>
        <KnownProxies>127.0.0.1</KnownProxies>
        <PublicHttpsPort>443</PublicHttpsPort>
      </NetworkConfiguration>
    '';

    configureHttpsScript = pkgs.writeShellScript "jellyfin-configure-https" ''
      set -euo pipefail

      if [ -f "/var/lib/acme/${cfg.https.acmeHost}/key.pem" ]; then
        ${pkgs.openssl}/bin/openssl pkcs12 -export \
          -out "${pfxPath}" \
          -inkey "/var/lib/acme/${cfg.https.acmeHost}/key.pem" \
          -in "/var/lib/acme/${cfg.https.acmeHost}/cert.pem" \
          -certfile "/var/lib/acme/${cfg.https.acmeHost}/chain.pem" \
          -passout pass:""

        chown jellyfin:jellyfin "${pfxPath}"
        chmod 600 "${pfxPath}"
      fi

      mkdir -p "$(dirname "${networkXml}")"
      chown jellyfin:jellyfin "$(dirname "${networkXml}")"

      if [ ! -f "${networkXml}" ]; then
        cp ${networkXmlTemplate} "${networkXml}"

        chown jellyfin:jellyfin "${networkXml}"
        chmod 644 "${networkXml}"
      else
        ${pkgs.xmlstarlet}/bin/xmlstarlet ed -L \
          -s '/NetworkConfiguration[not(EnableHttps)]' -t elem -n EnableHttps -v 'true' \
          -u '/NetworkConfiguration/EnableHttps' -v 'true' \
          -s '/NetworkConfiguration[not(HttpsPort)]' -t elem -n HttpsPort -v '${httpsPort}' \
          -u '/NetworkConfiguration/HttpsPort' -v '${httpsPort}' \
          -s '/NetworkConfiguration[not(CertificatePath)]' -t elem -n CertificatePath -v '${pfxPath}' \
          -u '/NetworkConfiguration/CertificatePath' -v '${pfxPath}' \
          -s '/NetworkConfiguration[not(CertificatePassword)]' -t elem -n CertificatePassword -v "" \
          -u '/NetworkConfiguration/CertificatePassword' -v "" \
          -s '/NetworkConfiguration[not(PublicHttpsPort)]' -t elem -n PublicHttpsPort -v '443' \
          -u '/NetworkConfiguration/PublicHttpsPort' -v '443' \
          -s '/NetworkConfiguration[not(KnownProxies)]' -t elem -n KnownProxies -v '127.0.0.1' \
          -u '/NetworkConfiguration/KnownProxies' -v '127.0.0.1' \
          "${networkXml}"
      fi
    '';
  in {
    options.jellyfin.https = {
      enable = lib.mkEnableOption "Jellyfin native HTTPS via PKCS#12 certificate";
      acmeHost = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Name of the security.acme.certs entry to convert to PFX for Jellyfin.";
      };

      listenPort = lib.mkOption {
        type = lib.types.port;
        default = 8920;
        description = "Port Jellyfin listens on for native HTTPS.";
      };
    };

    config = lib.mkMerge [
      {
        users = {
          groups.media = {};
          extraGroups.media.members = [
            user
            config.services.jellyfin.user
          ];
        };

        systemd.tmpfiles.rules = [
          "d  /srv/media                   0755 root    media - -"
          "d  /srv/media/shared            3770 root    media - -"
          "d  /srv/media/bastian           0750 ${user} media - -"
          "d  /srv/media/bastian/.jellyfin 0750 ${user} media - -"
        ];

        services.jellyfin = {
          enable = true;
          openFirewall = false;
        };

        environment.systemPackages = with pkgs; [
          jellyfin
          jellyfin-web
          jellyfin-ffmpeg
        ];
      }

      (lib.mkIf cfg.https.enable {
        assertions = [
          {
            assertion = cfg.https.acmeHost != "";
            message = "jellyfin.https.acmeHost must be set when jellyfin.https.enable is true";
          }
        ];

        systemd.services.jellyfin = {
          serviceConfig.ExecStartPre = ["+${configureHttpsScript}"];
          wants = ["acme-finished-${cfg.https.acmeHost}.target"];
          after = ["acme-finished-${cfg.https.acmeHost}.target"];
        };

        security.acme.certs.${cfg.https.acmeHost}.postRun = ''
          systemctl try-restart jellyfin.service
        '';
      })
    ];
  };
}
