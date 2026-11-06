{ inputs, ... }:
{
  flake.nixosModules.lanzaboote =
    {
      lib,
      options,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

      config = lib.mkMerge [
        # Persist signing keys for future rebuilds.
        (lib.optionalAttrs (options ? persistence) {
          persistence.directoriesWithMode."/var/lib/sbctl".mode = "0700";
        })

        {
          boot.loader = {
            # Lanzaboote replaces the stock systemd-boot installer.
            systemd-boot.enable = lib.mkForce false;

            efi = {
              canTouchEfiVariables = true;
              efiSysMountPoint = "/boot";
            };
          };

          boot.lanzaboote = {
            enable = true;

            # Keep Microsoft keys enrolled for option ROMs.
            pkiBundle = "/var/lib/sbctl";
          };

          # `sbctl create-keys` / `enroll-keys` / `verify` for out-of-band setup.
          environment.systemPackages = [ pkgs.sbctl ];
        }
      ];
    };
}
