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
  };
}
