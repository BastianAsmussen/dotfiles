{
  flake.nixosModules.qbittorrent = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkOption types;

    cfg = config.services.qbittorrent;
    wgService = "wireguard-${config.wireguard.interface}.service";
  in {
    options.qbittorrent.webuiAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address the qBittorrent WebUI binds to.";
    };

    config = {
      sops = {
        secrets = lib.genAttrs [
          "services/qbittorrent/webui/password-hash"
          "services/qbittorrent/proxy/address"
          "services/qbittorrent/proxy/username"
          "services/qbittorrent/proxy/password"
        ] (_: {owner = cfg.user;});

        templates."qbittorrent.conf" = {
          owner = cfg.user;
          content = ''
            [BitTorrent]
            Session\AnonymousModeEnabled=true
            Session\Encryption=1
            Session\GlobalUPSpeedLimit=10240
            Session\ProxyPeerConnections=true
            Session\QueueingSystemEnabled=false

            [LegalNotice]
            Accepted=true

            [Network]
            Proxy\AuthEnabled=true
            Proxy\HostnameLookupEnabled=false
            Proxy\IP=${config.sops.placeholder."services/qbittorrent/proxy/address"}
            Proxy\Password=${config.sops.placeholder."services/qbittorrent/proxy/password"}
            Proxy\Port=1080
            Proxy\Profiles\BitTorrent=true
            Proxy\Profiles\Misc=true
            Proxy\Profiles\RSS=true
            Proxy\Type=SOCKS5
            Proxy\Username=${config.sops.placeholder."services/qbittorrent/proxy/username"}

            [Preferences]
            Downloads\SavePath=/srv/media/torrents/
            General\Locale=en
            WebUI\Address=${config.qbittorrent.webuiAddress}
            WebUI\Username=admin
            WebUI\Password_PBKDF2=${config.sops.placeholder."services/qbittorrent/webui/password-hash"}
          '';
        };
      };

      services.qbittorrent = {
        enable = true;
        webuiPort = 8081;
      };

      systemd = {
        services.qbittorrent = {
          after = ["sops-install-secrets.service"] ++ lib.optional config.wireguard.enable wgService;
          bindsTo = lib.optional config.wireguard.enable wgService;
          serviceConfig.ExecStartPre = ''
            ${pkgs.coreutils}/bin/install -Dm600 \
              ${config.sops.templates."qbittorrent.conf".path} \
              "${cfg.profileDir}/qBittorrent/config/qBittorrent.conf"
          '';
        };

        tmpfiles.rules = [
          "d /srv/media/torrents 2770 ${cfg.user} media - -"
        ];
      };

      users.extraGroups.media.members = [cfg.user];
    };
  };
}
