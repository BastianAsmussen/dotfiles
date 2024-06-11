{
  lib,
  config,
  pkgs,
  ...
}: {
  options.custom.nvidia = {
    enable = lib.mkEnableOption "nvidia";
  };

  config = let
    cfg = config.custom.nvidia;
  in
    lib.mkIf cfg.enable {
      nixpkgs.config.cudaSupport = true;

      services.xserver.videoDrivers = ["nvidia"];

      environment.systemPackages = [pkgs.nvtopPackages.nvidia];

      hardware = {
        opengl = {
          enable = true;

          driSupport = true;
          driSupport32Bit = true;
        };

        nvidia = {
          modesetting.enable = true;

          powerManagement = {
	    enable = false;
            finegrained = false;
	  };

          open = false;
          nvidiaSettings = true;
        };
      };
    };
}

