{
  lib,
  config,
  ...
}: {
  options.network-manager.enable = lib.mkEnableOption "Enables Network Manager.";

  config = lib.mkIf config.network-manager.enable {
    networking.networkmanager.enable = true;
  };
}
