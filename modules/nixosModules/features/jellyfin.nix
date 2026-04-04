{
  flake.nixosModules.jellyfin = {
    config,
    pkgs,
    ...
  }: {
    services.jellyfin = {
      enable = true;

      openFirewall = true;
      user = "${config.preferences.user.name}";
    };

    environment.systemPackages = with pkgs; [
      jellyfin
      jellyfin-web
      jellyfin-ffmpeg
    ];

    nginx.reverseProxies.jellyfin = {
      enable = true;

      domain = "internal.asmussen.tech";
      upstream = "http://localhost:8096";

      ssl = {
        dnsProvider = "cloudflare";
        environmentFile = config.sops.templates."cloudflare-acme-env".path;
      };
    };

    # In-place patch of Jellyfin base URL.
    systemd.services.jellyfin.preStart = let
      networkXml = "${config.services.jellyfin.dataDir}/config/network.xml";
      baseUrl = config.nginx.reverseProxies.jellyfin.location;
    in
      # bash
      ''
        if [ -f "${networkXml}" ]; then
          ${pkgs.gnused}/bin/sed -i 's|<BaseUrl>[^<]*</BaseUrl>|<BaseUrl>${baseUrl}</BaseUrl>|' "${networkXml}"
        fi
      '';
  };
}
