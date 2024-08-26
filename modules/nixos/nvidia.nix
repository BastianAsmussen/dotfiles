{
  lib,
  config,
  ...
}: {
  options.nvidia.enable = lib.mkEnableOption "Enables NVIDIA drivers.";

  config = lib.mkIf config.nvidia.enable {
    hardware = {
      nvidia = {
        modesetting.enable = true;

        powerManagement = {
          enable = true;
          finegrained = false;
        };

        open = false;
        nvidiaSettings = true;

        package = config.boot.kernelPackages.nvidiaPackages.production;
      };

      # Enable graphics driver.
      graphics = {
        enable = true;
        enable32Bit = true;
      };

      # Enable the container toolkit if Docker is enabled.
      nvidia-container-toolkit.enable = config.docker.enable;
    };

    # Load NVIDIA drivers for Xorg and Wayland.
    services.xserver.videoDrivers = ["nvidia"];
  };
}
