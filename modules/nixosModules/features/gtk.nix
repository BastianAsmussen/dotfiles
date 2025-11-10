{
  flake.nixosModules.gtk = {
    pkgs,
    lib,
    ...
  }: let
    theme-name = "Catppucin";
    theme-package = pkgs.catppuccin-gtk.override {
      variant = "mocha";
    };

    icon-theme-package = pkgs.adwaita-icon-theme;
    icon-theme-name = "Adwaita";

    gtk-settings = ''
      [Settings]
      gtk-icon-theme-name = ${icon-theme-name}
      gtk-theme-name = ${theme-name}
    '';
  in {
    environment = {
      variables.GTK_THEME = theme-name;
      etc = {
        "xdg/gtk-3.0/settings.ini".text = gtk-settings;
        "xdg/gtk-4.0/settings.ini".text = gtk-settings;
      };

      systemPackages = [
        theme-package
        icon-theme-package

        pkgs.gtk3
        pkgs.gtk4
      ];
    };

    programs.dconf = {
      enable = lib.mkDefault true;
      profiles.user.databases = [
        {
          lockAll = false;
          settings = {
            "org/gnome/desktop/interface" = {
              gtk-theme = theme-name;
              icon-theme = icon-theme-name;
              color-scheme = "prefer-dark";
            };
          };
        }
      ];
    };
  };
}
