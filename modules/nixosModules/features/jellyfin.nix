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
  };
}
