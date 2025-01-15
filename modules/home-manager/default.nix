{
  userInfo,
  pkgs,
  ...
}: {
  imports = [
    ./desktop
    ./terminal
    ./dconf.nix
    ./qemu.nix
    ./rust.nix
  ];

  gpg = {
    enable = true;

    keyTrustMap."0x0FE5A355DBC92568-2024-08-09.asc" = "ultimate";
  };

  home = {
    inherit (userInfo) username;
    homeDirectory = "/home/${userInfo.username}";

    packages = with pkgs; [
      man-pages
      man-pages-posix
      qbittorrent
      gitui
      wget
      go
      jq
      manix
      tlrc
      teams-for-linux
      bitwarden
      pika-backup
      mpv
      cabal-install
      mit
      calculator
      myip
      system-size
      todo
    ];

    stateVersion = "24.05";
  };

  programs = {
    home-manager.enable = true;
    man.generateCaches = true;
  };

  # Nicely reload system units when changing configs.
  systemd.user.startServices = "sd-switch";
}
