{
  pkgs,
  lib,
  config,
  ...
}: {
  options.stylix = with lib; {
    colorScheme = mkOption {
      default = "catppuccin-mocha";
      description = "The Base16 theme to use.";
      type = types.str;
    };

    wallpaper = mkOption {
      default = ./../../wallpapers/tokyo.png;
      description = "The wallpaper image to use.";
      type = types.path;
    };
  };

  config = lib.mkIf config.stylix.enable {
    stylix = {
      base16Scheme = "${pkgs.base16-schemes}/share/themes/${config.stylix.colorScheme}.yaml";
      image = config.stylix.wallpaper;

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
