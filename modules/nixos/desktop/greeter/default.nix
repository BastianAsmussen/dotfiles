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
    # Hint Electron apps to use Wayland.
    environment.sessionVariables.NIXOS_OZONE_WL = mkIf cfg.greeter.useWayland "1";
  };
}
