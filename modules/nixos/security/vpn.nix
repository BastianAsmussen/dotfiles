{
  lib,
  config,
  pkgs,
  ...
}: {
  options.vpn.enable = lib.mkEnableOption "Enables MullvadVPN.";

  config = lib.mkIf config.vpn.enable {
    environment.systemPackages = [pkgs.mullvad-vpn];
    services = {
      resolved.enable = true;
      mullvad-vpn.enable = true;
    };

    # Relax the RP filtering a little.
    boot.kernel.sysctl = lib.mkForce {
      "net.ipv4.conf.default.rp_filter" = 2;
      "net.ipv4.conf.all.rp_filter" = 2;
    };
  };
}
