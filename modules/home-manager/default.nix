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
  ];

  gpg = {
    enable = true;

    keyTrustMap."0x0FE5A355DBC92568-2024-08-09.asc" = "ultimate";
  };

  home = {
    inherit (userInfo) username;
    homeDirectory = "/home/${userInfo.username}";

    packages = with pkgs; [
      qbittorrent
      gitui
      wget
      go
      jq
      manix
      tlrc
      teams-for-linux
      bitwarden
      spotify
      pika-backup
      mpv
      cabal-install
      rustup
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
