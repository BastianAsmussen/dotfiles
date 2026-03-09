{
  flake.homeModules.goxlr = let
    configDir = ".local/share/goxlr-utility";
  in {
    home.file = {
      "${configDir}/profiles".source = ./goxlr-config/profiles;
      "${configDir}/mic-profiles".source = ./goxlr-config/mic-profiles;
    };
  };
}
