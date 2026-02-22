{
  lib,
  config,
  pkgs,
  ...
}: {
  options.bottles.enable = lib.mkEnableOption "Installs Bottles package.";

  config = lib.mkIf config.bottles.enable {
    environment.systemPackages = [pkgs.bottles];
  };
}
