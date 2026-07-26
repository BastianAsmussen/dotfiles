{
  flake.homeModules.torBrowser =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.tor-browser;

      libcWrappedPackage = pkgs.symlinkJoin {
        name = "tor-browser-libc-allocator";
        paths = [ cfg.package ];
        nativeBuildInputs = [ pkgs.makeWrapper ];

        postBuild = ''
          wrapProgram "$out/bin/tor-browser" \
            --set LD_PRELOAD "${lib.getLib pkgs.glibc}/lib/libc.so.6"
        '';

        inherit (cfg.package) meta;
      };
    in
    {
      options.programs.tor-browser = {
        enable = lib.mkEnableOption "Tor Browser";

        package = lib.mkPackageOption pkgs "tor-browser" { };

        forceLibcAllocator = lib.mkEnableOption "the libc allocator for Tor Browser";
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ (if cfg.forceLibcAllocator then libcWrappedPackage else cfg.package) ];
      };
    };
}
