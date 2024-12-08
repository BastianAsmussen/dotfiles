{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options.nvidia.enable = mkEnableOption "Enables NVIDIA drivers.";
  config = mkIf config.nvidia.enable {
    hardware = {
      nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.production;

        modesetting.enable = true;
        powerManagement = {
          enable = false;
          finegrained = false;
        };

        open = false;
        nvidiaSettings = true;
      };

      # Enable graphics driver.
      graphics = {
        enable = true;
        enable32Bit = true;

        extraPackages = [pkgs.vulkan-validation-layers];
      };

      # Enable the container toolkit if Docker is enabled.
      nvidia-container-toolkit.enable = config.docker.enable;
    };

    # Load NVIDIA drivers for Xorg and Wayland.
    services.xserver.videoDrivers = ["nvidia"];

    environment.variables = {
      # Required to run the correct GBM backend for NVIDIA GPUs on Wayland.
      GBM_BACKEND = mkIf config.desktop.greeter.useWayland "nvidia-drm";
      # Apparently, without this nouveau may attempt to be used instead.
      # (despite it being blacklisted)
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";

      LIBVA_DRIVER_NAME = "nvidia";
      __GL_GSYNC_ALLOWED = "1";
      __GL_VRR_ALLOWED = "0";
      WLR_DRM_NO_ATOMIC = "1";
      WLR_RENDERER = "vulkan";

      # Hardware cursors are currently broken on NVIDIA.
      WLR_NO_HARDWARE_CURSORS = "1";
    };
  };
}
