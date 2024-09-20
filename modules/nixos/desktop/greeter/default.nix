{
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption types mkIf;

  cfg = config.desktop;
in {
  imports = [
    ./gdm.nix
    ./sddm.nix
  ];

  options.desktop.greeter.useWayland = mkOption {
    default = true;
    description = "Whether to use the Wayland compositor or not.";
    type = types.bool;
  };

  config = {
    environment.sessionVariables = mkIf cfg.greeter.useWayland {
      NIXOS_OZONE_WL = "1"; # Hint Electron apps to use Wayland.
      GTK_BACKEND = "wayland"; # Tell GTK programs to use Wayland.
      QT_QPA_PLATFORM = "wayland"; # Tell Qt programs to use Wayland.
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      SDL_VIDEODRIVER = "wayland";
      _JAVA_AWT_WM_NONREPARENTING = 1;
    };
  };
}
