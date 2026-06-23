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
        # Lanzaboote manages systemd-boot; disable the stock installer.
        systemd-boot.enable = lib.mkForce false;

        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";
        };
      };

      boot.lanzaboote = {
        enable = true;

        # PK/KEK/db and the root-only secret key. Microsoft keys stay enrolled
        # (the default) so option ROMs still run under Secure Boot.
        pkiBundle = "/var/lib/sbctl";
      };

      # `sbctl create-keys` / `enroll-keys` / `verify` for out-of-band key setup.
      environment.systemPackages = [ pkgs.sbctl ];
    };
}
