{pkgs, ...}: {
  stylix = {
    enable = true;

    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    image = ../../wallpapers/tokyo.png;

    polarity = "dark";

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
    };

    fonts = with pkgs; {
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
