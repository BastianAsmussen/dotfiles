{
  flake.nixosModules.goxlr =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.goxlr-utility ];

      services.goxlr-utility = {
        enable = true;
        # Only niri starts the daemon; XDG autostart races it and resets
        # settings.
        autoStart.xdg = false;
      };

      preferences.autostart = [ "${pkgs.goxlr-utility}/bin/goxlr-daemon" ];
    };
}
