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
      gitui
      wget
      go
      jq
      manix
      tlrc
      cabal-install
      mit
      calculator
      copy-file
      repo-cloner
      todo
      cargo-info
      bitwarden-desktop
      teams-for-linux
      qbittorrent
      libreoffice-fresh
      airtame
      freecad-wayland
      mpv
      winboat
      freerdp
      anki
      diesel-cli
    ];

    stateVersion = "25.11";
  };

  programs = {
    home-manager.enable = true;
    man.generateCaches = true;
  };

  # Nicely reload system units when changing configs.
  systemd.user.startServices = "sd-switch";
}
