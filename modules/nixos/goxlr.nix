{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options.goxlr.enable = mkEnableOption "Enables GoXLR drivers.";

  config = mkIf config.goxlr.enable {
    environment.systemPackages = [pkgs.goxlr-utility];
    services.goxlr-utility = {
      enable = true;
      autoStart.xdg = true;
    };

    desktop.audio.pipewire.enable = true;
  };
}
