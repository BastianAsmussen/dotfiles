{
  pkgs,
  lib,
  config,
  ...
}: {
  options.stylix.colorScheme = lib.mkOption {
    default = "catppuccin-mocha";
    description = "The Base16 theme to use.";
  };

  config = lib.mkIf config.stylix.enable {
    stylix = {
      base16Scheme = "${pkgs.base16-schemes}/share/themes/${config.stylix.colorScheme}.yaml";
      image = ./../wallpapers/wallpaper.png;

      targets.grub.useImage = true;

      polarity = "dark";

      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
      };

      fonts = {
        monospace = {
          package = pkgs.nerdfonts.override {fonts = ["JetBrainsMono"];};
          name = "JetBrainsMono Nerd Font Mono";
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
    };
  };
}
