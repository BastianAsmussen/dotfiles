{
  flake.nixosModules.greeter = {
    lib,
    config,
    ...
  }: let
    inherit (lib) mkOption types mkIf mkEnableOption;

    cfg = config.desktop.greeter;
  in {
    options.desktop.greeter = {
      useWayland = mkOption {
        default = true;
        description = "Whether to use the Wayland compositor or not.";
        type = types.bool;
      };

      gdm.enable = mkEnableOption "Enables the `GDM` greeter.";
    };

    config = lib.mkMerge [
      {
        environment.sessionVariables = mkIf cfg.useWayland {
          NIXOS_OZONE_WL = "1";
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
          GTK_BACKEND = "wayland";
          QT_QPA_PLATFORM = "wayland";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
          QT_AUTO_SCREEN_SCALE_FACTOR = "1";
          SDL_VIDEODRIVER = "wayland";
          _JAVA_AWT_WM_NONREPARENTING = 1;
        };
      }

      (mkIf cfg.gdm.enable {
        services.displayManager.gdm = {
          enable = true;
          wayland = cfg.useWayland;
          autoSuspend = false;
        };
      })
    ];
  };
}
