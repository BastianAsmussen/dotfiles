{
  flake.nixosModules.jellyfin = {
    config,
    pkgs,
    ...
  }: let
    user = config.preferences.user.name;
  in {
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
  };
}
