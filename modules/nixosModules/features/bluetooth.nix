{
  flake.nixosModules.bluetooth =
    { lib, pkgs, ... }:
    {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };

      services.blueman.enable = true;
      systemd.user.services.mpris-proxy = {
        description = "Mpris proxy.";
        after = [
          "network.target"
          "sound.target"
        ];

        wantedBy = [ "default.target" ];
        serviceConfig.ExecStart = lib.getExe' pkgs.bluez "mpris-proxy";
      };
    };
}
