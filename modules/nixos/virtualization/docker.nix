{
  lib,
  config,
  ...
}: {
  options.docker = with lib; {
    enable = mkEnableOption "Enables Docker support.";

    storageDriver = mkOption {
      default = "btrfs";
      description = "The filesystem that Docker will use.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.docker.enable {
      virtualisation.docker = {
        enable = true;

        storageDriver = config.docker.storageDriver;
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
      };
    })
    (lib.mkIf config.nvidia.enable {
      virtualisation.docker = {
        enableNvidia = true;
        extraOptions = "--default-runtime=nvidia";
      };
    })
  ];
}
