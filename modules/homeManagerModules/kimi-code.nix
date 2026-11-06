{
  flake.homeModules.kimiCode =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.kimi-code ];

      persistence.directoriesWithMode.".kimi-code" = "0700";
    };
}
