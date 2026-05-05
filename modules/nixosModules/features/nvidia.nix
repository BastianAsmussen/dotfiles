{
  flake.nixosModules.nvidia = {
    config,
    pkgs,
    ...
  }: {
    hardware = {
      nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.beta;
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
        extraPackages = with pkgs; [
          libva-vdpau-driver
          libvdpau
          libvdpau-va-gl
          nvidia-vaapi-driver
          vdpauinfo
          libva
          libva-utils
        ];
      };
    };

    # Boot to text mode.
    boot.initrd.kernelModules = ["nvidia"];

    # Load NVIDIA drivers for Xorg and Wayland.
    services.xserver.videoDrivers = ["nvidia"];
    environment = {
      systemPackages = [pkgs.nvtopPackages.nvidia];
      variables = {
        # Required to run the correct GBM backend for NVIDIA GPUs on Wayland.
        GBM_BACKEND = "nvidia-drm";

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

    # Set up Multi-Process Service (MPS).
    systemd.services.nvidia-mps = {
      description = "NVIDIA CUDA Multi-Process Service";
      after = ["nvidia-persistenced.service"];
      requires = ["nvidia-persistenced.service"];
      wantedBy = ["multi-user.target"];
      path = [config.hardware.nvidia.package.bin];
      serviceConfig = {
        Type = "forking";
        ExecStart = "${config.hardware.nvidia.package.bin}/bin/nvidia-cuda-mps-control -d";
        ExecStop = "${pkgs.writeShellScript "nvidia-mps-stop" ''
          echo quit | ${config.hardware.nvidia.package.bin}/bin/nvidia-cuda-mps-control
        ''}";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
