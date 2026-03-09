# Shared user profile for bastian, imported on every host.
# Host-specific packages belong in the host configuration instead.
{
  flake.homeModules.bastian = {pkgs, ...}: {
    gpg = {
      enable = true;

      keyTrustMap."0x0FE5A355DBC92568-2024-08-09.asc" = "ultimate";
    };

    home.packages = with pkgs; [
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
      mpv
      winboat
      freerdp
      anki
      diesel-cli
      postman
    ];

    programs.man.generateCaches = true;
  };
}
