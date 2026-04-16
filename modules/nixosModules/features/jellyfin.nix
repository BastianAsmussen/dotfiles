{
  flake.nixosModules.jellyfin = {
    config,
    lib,
    pkgs,
    ...
  }: {
    options.jellyfin.baseUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Base URL path written into Jellyfin's network.xml.";
    };

    config = {
      services.jellyfin = {
        enable = true;
        openFirewall = false;
        user = config.preferences.user.name;
      };

      environment.systemPackages = with pkgs; [
        jellyfin
        jellyfin-web
        jellyfin-ffmpeg
      ];

      systemd.services.jellyfin.preStart = let
        networkXml = "${config.services.jellyfin.dataDir}/config/network.xml";
      in ''
        if [ -f "${networkXml}" ]; then
          ${pkgs.gnused}/bin/sed -i \
            's|<BaseUrl>[^<]*</BaseUrl>|<BaseUrl>${config.jellyfin.baseUrl}</BaseUrl>|' \
            "${networkXml}"
        fi
      '';
    };
  };
}
