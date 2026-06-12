{
  flake.nixosModules.goxlr =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.goxlr-utility ];

      services.goxlr-utility = {
        enable = true;
        # The daemon is spawned by niri below; XDG autostart would launch a
        # second racing instance that fails its IPC bind and can rewrite
        # settings.json with defaults.
        autoStart.xdg = false;
      };

      preferences.autostart = [ "${pkgs.goxlr-utility}/bin/goxlr-daemon" ];
    };
}
