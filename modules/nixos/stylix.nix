{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.stylix;
in {
  options.stylix = with lib; {
    colorScheme = mkOption {
      default = "catppuccin-mocha";
      description = "The Base16 theme to use.";
      type = types.str;
    };

    wallpaper = mkOption {
      default = ../../wallpapers/tokyo.png;
      description = "The wallpaper image to use.";
      type = types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    stylix = {
      base16Scheme = "${pkgs.base16-schemes}/share/themes/${cfg.colorScheme}.yaml";
      image = cfg.wallpaper;

      targets.grub.useImage = true;

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
  };
}
