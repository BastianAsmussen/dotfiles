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
        # Persist the signing keys; without them the next rebuild cannot sign.
        (lib.optionalAttrs (options ? persistence) {
          persistence.directoriesWithMode."/var/lib/sbctl" = "0700";
        })

        {
          boot.loader = {
            # Lanzaboote manages systemd-boot; disable the stock installer.
            systemd-boot.enable = lib.mkForce false;

            efi = {
              canTouchEfiVariables = true;
              efiSysMountPoint = "/boot";
            };
          };

          boot.lanzaboote = {
            enable = true;

            # PK/KEK/db and the root-only secret key. Microsoft keys stay
            # enrolled (the default) so option ROMs still run under Secure Boot.
            pkiBundle = "/var/lib/sbctl";
          };

          # `sbctl create-keys` / `enroll-keys` / `verify` for out-of-band setup.
          environment.systemPackages = [ pkgs.sbctl ];
        }
      ];
    };
}
