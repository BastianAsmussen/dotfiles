{
  lib,
  config,
  ...
}: {
  imports = [
    ./vaapi.nix
  ];

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

        vaapi = {
          enable = true;

          firefox.enable = true;
        };
      };

      # Enable graphics driver.
      graphics = {
        enable = true;
        enable32Bit = true;
      };

      # Enable the container toolkit if Docker is enabled.
      nvidia-container-toolkit.enable = config.docker.enable;
    };

    nixpkgs.overlays = [
      (_: final: {
        wlroots_0_16 = final.wlroots_0_16.overrideAttrs (_: {
          patches = [./wlroots-nvidia.patch];
        });
      })
    ];

    # Load NVIDIA drivers for Xorg and Wayland.
    services.xserver.videoDrivers = ["nvidia"];

    boot.extraModprobeConfig =
      "options nvidia "
      + lib.concatStringsSep " " [
        # nvidia assume that by default your CPU does not support PAT,
        # but this is effectively never the case in 2023
        "NVreg_UsePageAttributeTable=1"
        # This may be a noop, but it's somewhat uncertain:
        "NVreg_EnablePCIeGen3=1"
        # This is sometimes needed for ddc/ci support, see
        # https://www.ddcutil.com/nvidia/
        #
        # Current monitor does not support it, but this is useful for
        # the future
        "NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100"
        # When (if!) I get another nvidia GPU, check for resizeable bar
        # settings
      ];

    environment.variables = {
      # Required to run the correct GBM backend for NVIDIA GPUs on Wayland.
      GBM_BACKEND = "nvidia-drm";
      # Apparently, without this nouveau may attempt to be used instead.
      # (despite it being blacklisted)
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";

      # Hardware cursors are currently broken on NVIDIA.
      WLR_NO_HARDWARE_CURSORS = "1";
    };
  };
}
