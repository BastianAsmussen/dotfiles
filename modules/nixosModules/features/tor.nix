{
  flake.nixosModules.tor =
    {
      lib,
      options,
      pkgs,
      ...
    }:
    {
      config = lib.mkMerge [
        # Persist Tor's entry guards to avoid a new fingerprint each reboot.
        (lib.optionalAttrs (options ? persistence) {
          persistence.directories = [
            {
              directory = "/var/lib/tor";
              user = "tor";
              group = "tor";
              mode = "0700";
            }
          ];
        })

        {
          services.tor = {
            enable = true;
            client.enable = true;
          };

          environment.systemPackages = [ pkgs.torsocks ];
        }
      ];
    };
}
