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
        # The keys this module signs the boot chain with. On a tmpfs root they
        # vanish every reboot and the next rebuild cannot sign, which leaves an
        # unbootable machine; owning the entry here means importing lanzaboote
        # is enough. Hosts without preservation get an empty attrset instead.
        (lib.optionalAttrs (options ? persistence) {
          persistence.directoriesWithMode."/var/lib/sbctl" = "0700";
        })

        {
          boot.loader = {
            # Lanzaboote installs and drives the systemd-boot EFI binary itself, so
            # the stock systemd-boot installer must be disabled or the two collide.
            systemd-boot.enable = lib.mkForce false;

            efi = {
              canTouchEfiVariables = true;
              efiSysMountPoint = "/boot";
            };
          };

          boot.lanzaboote = {
            enable = true;

            # PK/KEK/db plus the root-only secret key live here.
            # `includeMicrosoftKeys` keeps its default (true) so Microsoft-signed
            # option ROMs still run once Secure Boot is enforced.
            #
            pkiBundle = "/var/lib/sbctl";
          };

          # `sbctl create-keys` / `enroll-keys` / `verify` for out-of-band setup.
          environment.systemPackages = [ pkgs.sbctl ];
        }
      ];
    };
}
