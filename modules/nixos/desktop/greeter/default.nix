{
  lib,
  config,
  ...
}: {
  imports = [
    ./gdm.nix
    ./sddm.nix
  ];

  options.desktop.greeter.useWayland = lib.mkOption {
    default = true;
    description = "Whether to use the Wayland compositor or not.";
    type = lib.types.bool;
  };

  config = {
    # Hint Electron apps to use Wayland.
    environment.sessionVariables.NIXOS_OZONE_WL = lib.mkIf config.desktop.greeter.useWayland "1";
  };
}
