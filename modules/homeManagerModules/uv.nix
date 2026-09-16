{
  flake.homeModules.uv =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.uv ];

      persistence.cache.directories = [ ".cache/uv" ];
    };
}
