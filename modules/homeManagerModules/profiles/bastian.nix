# Shared user profile for bastian, imported on every host.
# Host-specific packages belong in the host configuration instead.
{
  flake.homeModules.bastian =
    { pkgs, ... }:
    {
      gpg = {
        enable = true;
        keyTrustMap = {
          "0xD92D668B77A29897-2026-06-08.asc" = "ultimate";
          "0x0FE5A355DBC92568-2024-08-09.asc" = "ultimate";
          "0x3B89704887DFEF65-2024-08-23.asc" = "full";
        };
      };

      home = {
        # /run/wrappers/bin is appended after user profiles by NixOS; prepend it
        # so setcap wrappers take precedence.
        sessionPath = [ "/run/wrappers/bin" ];

        packages = with pkgs; [
          anki
          bacon
          cabal-install
          calculator
          cargo-info
          copy-file
          diesel-cli
          fselect
          gitui
          go
          hyperfine
          jq
          jless
          just
          libreoffice-fresh
          man-pages
          man-pages-posix
          manix
          mit
          mpv
          postman
          repo-cloner
          rusty-man
          sl
          teams-for-linux
          tlrc
          todo
          tokei
          tuxedo
          wget
          xh
        ];
      };
    };
}
