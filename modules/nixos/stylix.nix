{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.stylix.enable {
    stylix = {
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      image = ./../wallpapers/wallpaper.png;

      polarity = "dark";

      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
      };
    };
  };
}
