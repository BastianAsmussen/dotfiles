{
  hmOptions,
  pkgs,
  ...
}: {
  imports = [
    ./desktop
    ./terminal
  ];

  gpg = {
    enable = true;

    keyTrustMap."0x0FE5A355DBC92568-2024-08-09.asc" = "ultimate";
  };

  programs.man.generateCaches = true;

  home = {
    username = "${hmOptions.username}";
    homeDirectory = "/home/${hmOptions.username}";

    packages = with pkgs; [
      qbittorrent
      gitui
      wget
      go
      manix
      tlrc
      teams-for-linux
      bitwarden
      spotify
      pika-backup
      mpv
    ];

    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs.
  systemd.user.startServices = "sd-switch";
}
