{pkgs, ...}: {
  stylix = {
    enable = true;

    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    image = ../../assets/wallpapers/tokyo.png;
    polarity = "dark";
    cursor = {
      package = pkgs.stable.bibata-cursors;
      name = "Bibata-Modern-Ice";
    };

    fonts = with pkgs; {
      sizes = {
        applications = 12;
        terminal = 14;
        desktop = 10;
        popups = 10;
      };

      monospace = {
        package = nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
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
