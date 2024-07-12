{
  lib,
  config,
  ...
}: {
  options.vpn.enable = lib.mkEnableOption "Enables MullvadVPN.";

  config = lib.mkIf config.vpn.enable {
    services = {
      resolved.enable = true;
      mullvad-vpn.enable = true;
    };
  };
}
