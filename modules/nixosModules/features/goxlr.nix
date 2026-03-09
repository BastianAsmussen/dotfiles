{
  flake.nixosModules.goxlr = {pkgs, ...}: {
    environment.systemPackages = [pkgs.goxlr-utility];

    services.goxlr-utility = {
      enable = true;
      autoStart.xdg = true;
    };
  };
}
