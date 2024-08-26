{
  lib,
  config,
  ...
}: {
  options.docker = {
    enable = lib.mkEnableOption "Enables Docker support.";

    storageDriver = lib.mkOption {
      default = "btrfs";
      description = "The filesystem that Docker will use.";
    };
  };

  config = lib.mkIf config.docker.enable {
    virtualisation.docker = {
      enable = true;
      inherit (config.docker) storageDriver;

      rootless = {
        enable = true;
        setSocketVariable = true;
      };

      autoPrune.enable = true;
    };
  };
}
