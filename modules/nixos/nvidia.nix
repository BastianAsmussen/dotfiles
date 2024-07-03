{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    nvidia.enable = lib.mkEnableOption "Enables NVIDIA drivers.";
  };

  config = lib.mkIf config.nvidia.enable {
    hardware = {
      # Enable NVIDIA drivers.
      nvidia = {
        modesetting.enable = true;

        powerManagement = {
          enable = false;
          finegrained = false;
        };

        open = false;
        nvidiaSettings = true;

        package = config.boot.kernelPackages.nvidiaPackages.production;
      };

      # Enable OpenGL.
      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };

    # Load NVIDIA drivers for Xorg and Wayland.
    services.xserver.videoDrivers = ["nvidia"];
  };
}
