{ inputs, ... }:
{
  flake.nixosModules.lanzaboote =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

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
        # NOTE: hosts with an ephemeral (tmpfs) root MUST persist this path, or
        # the keys vanish on reboot and the next rebuild cannot sign the boot
        # chain. See epsilon's `persistence` config.
        pkiBundle = "/var/lib/sbctl";
      };

      # `sbctl create-keys` / `enroll-keys` / `verify` for out-of-band key setup.
      environment.systemPackages = [ pkgs.sbctl ];
    };
}
