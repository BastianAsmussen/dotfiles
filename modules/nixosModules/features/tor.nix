{
  flake.nixosModules.tor =
    { pkgs, ... }:
    {
      services.tor = {
        enable = true;
        client.enable = true;
      };

      environment.systemPackages = [ pkgs.torsocks ];
    };
}
