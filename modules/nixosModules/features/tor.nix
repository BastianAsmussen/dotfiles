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
        # Keep a stable entry-guard set instead of selecting new guards on
        # every reboot, which is a fingerprint in itself.
        # Hosts without preservation get an empty attrset instead.
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
