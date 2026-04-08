{
  flake.nixosModules.goxlr = {pkgs, ...}: {
    environment.systemPackages = [pkgs.goxlr-utility];

    services.goxlr-utility = {
      enable = true;
      autoStart.xdg = true;
    };

    preferences.autostart = ["${pkgs.goxlr-utility}/bin/goxlr-launcher &"];
  };
}
