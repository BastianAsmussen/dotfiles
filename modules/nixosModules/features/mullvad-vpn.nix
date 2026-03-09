{
  flake.nixosModules.mullvadVpn = {pkgs, ...}: {
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
