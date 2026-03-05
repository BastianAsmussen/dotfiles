{
  lib,
  config,
  pkgs,
  ...
}: {
  options.mullvad-vpn.enable = lib.mkEnableOption "Enables MullvadVPN.";

  config = lib.mkIf config.mullvad-vpn.enable {
    environment.systemPackages = [pkgs.mullvad-vpn];

    services = {
      resolved.enable = true;
      mullvad-vpn = {
        enable = true;

        package = pkgs.mullvad-vpn;
      };
    };
  };
}
