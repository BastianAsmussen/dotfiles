# Shared user profile for bastian, imported on every host.
# Host-specific packages belong in the host configuration instead.
{
  flake.homeModules.bastian = {pkgs, ...}: {
    gpg = {
      enable = true;
      keyTrustMap = {
        "0x0FE5A355DBC92568-2024-08-09.asc" = "ultimate";
        "0x3B89704887DFEF65-2024-08-23.asc" = "marginal";
      };
    };

    home = {
      # /run/wrappers/bin is appended after user profiles by NixOS; prepend it
      # so setcap wrappers take precedence.
      sessionPath = ["/run/wrappers/bin"];

      packages = with pkgs; [
        anki
        bacon
        cabal-install
        calculator
        cargo-info
        copy-file
        diesel-cli
        freerdp
        fselect
        gitui
        go
        hyperfine
        jq
        just
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
        teams-for-linux
        tlrc
        todo
        tokei
        wget
        xh
      ];
    };
  };
}
