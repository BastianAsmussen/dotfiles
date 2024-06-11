{ inputs, pkgs, ... }:
{
  imports = [
    inputs.stylix.homeManagerModules.stylix
  ];

  stylix.enable = true;
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
  stylix.image = ../../wallpaper.png;

  stylix.cursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
  };

  stylix.fonts = {
    monospace = {
      package = pkgs.nerdfonts.override { fonts = ["JetBrainsMono"]; };
      name = "JetbrainsMono Nerd Font Mono";
    };
    sansSerif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Sans";
    };
    serif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Serif";
    };
  };

  stylix.polarity = "dark";
}

