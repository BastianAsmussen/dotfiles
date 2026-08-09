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
        spicetify
        torBrowser
      ];

      programs.tor-browser.enable = true;

      # schizofox reads home.pointerCursor.package unconditionally. On a NixOS
      # host the stylix module owns that option, so only supply it when running
      # as standalone home-manager (osConfig == null), where no stylix cursor
      # exists to populate it.
      home.pointerCursor = lib.mkIf (osConfig == null) {
        enable = true;
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
        size = 32;
      };
    };
}
