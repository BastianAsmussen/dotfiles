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
        # Prepend setcap wrappers ahead of user profiles.
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
          obsidian
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
