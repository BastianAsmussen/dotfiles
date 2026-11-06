{
  flake.nixosModules.goxlr =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.goxlr-utility ];

      services.goxlr-utility = {
        enable = true;
        # XDG autostart races niri and resets settings.
        autoStart.xdg = false;
      };

      preferences.autostart = [ "${pkgs.goxlr-utility}/bin/goxlr-daemon" ];
    };
}
