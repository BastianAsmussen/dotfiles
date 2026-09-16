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
        nixcord
        noctalia
        obsidian
        spicetify
        torBrowser
      ];

      programs.tor-browser.enable = true;

      # Standalone HM must supply the cursor that Stylix provides on NixOS.
      home.pointerCursor = lib.mkIf (osConfig == null) {
        enable = true;
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
        size = 32;
      };
    };
}
