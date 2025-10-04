{
  lib,
  osConfig,
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

  disabledModules = lib.optionals (osConfig ? wsl.enable) [
    ./desktop
    ./dconf.nix
  ];

  gpg = {
    enable = true;

    keyTrustMap."0x0FE5A355DBC92568-2024-08-09.asc" = "ultimate";
  };

  home = {
    inherit (userInfo) username;
    homeDirectory = "/home/${userInfo.username}";

    packages = lib.mkMerge [
      (with pkgs; [
        man-pages
        man-pages-posix
        gitui
        wget
        go
        jq
        fd
        manix
        tlrc
        cabal-install
        mit
        calculator
        copy-file
        nixpoch
        todo
        rusty-man
        cargo-info
        yt-dlp
      ])
      (lib.mkIf (!osConfig ? wsl.enable) (with pkgs; [
        bitwarden
        teams-for-linux
        qbittorrent
        pika-backup
        libreoffice-fresh
        airtame
        freecad-wayland
        mpv
        telegram-desktop
      ]))
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
