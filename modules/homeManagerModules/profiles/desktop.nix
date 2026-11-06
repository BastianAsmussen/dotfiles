# GUI application set shared across desktop/laptop hosts.
{ self, ... }:
{
  flake.homeModules.desktop =
    {
      pkgs,
      lib,
      osConfig ? null,
      ...
    }:
    {
      imports = with self.homeModules; [
        alacritty
        firefox
        learnharness
        nixcord
        obsidian
        spicetify
        torBrowser
      ];

      programs.tor-browser.enable = true;

      # Only supply NixOS-owned cursor when unset.
      home.pointerCursor = lib.mkIf (osConfig == null) {
        enable = true;
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
        size = 32;
      };
    };
}
