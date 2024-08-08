{
  lib,
  osOptions,
  ...
}: let
  configDir = ".local/share/goxlr-utility";
in {
  config = lib.mkIf osOptions.goxlr.enable {
    home.file = {
      "${configDir}/profiles".source = ./config/profiles;
      "${configDir}/mic-profiles".source = ./config/mic-profiles;
    };
  };
}
