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
      SDL_VIDEODRIVER = "wayland";
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      _JAVA_AWT_WM_NONREPARENTING = 1;
    };
  };
}
