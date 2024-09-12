{pkgs, ...}: let
  scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
in {
  environment.sessionVariables.STYLIX_SCHEME = scheme;

  stylix = {
    enable = true;

    base16Scheme = scheme;
    image = ../../assets/wallpapers/tokyo.png;
    polarity = "dark";
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
    };

    fonts = with pkgs; {
      sizes = {
        applications = 12;
        terminal = 15;
        desktop = 10;
        popups = 10;
      };

      monospace = {
        package = nerdfonts.override {fonts = ["JetBrainsMono"];};
        name = "JetBrainsMono Nerd Font Mono";
      };

      sansSerif = {
        package = dejavu_fonts;
        name = "DejaVu Sans";
      };

      serif = {
        package = dejavu_fonts;
        name = "DejaVu Serif";
      };
    };
  };
}
