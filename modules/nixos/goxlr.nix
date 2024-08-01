{
  lib,
  config,
  pkgs,
  ...
}: {
  options.goxlr.enable = lib.mkEnableOption "Enables GoXLR drivers.";

  config = lib.mkIf config.goxlr.enable {
    environment.systemPackages = with pkgs; [
      goxlr-utility
    ];

    services.goxlr-utility = {
      enable = true;

      autoStart.xdg = true;
    };
  };
}
