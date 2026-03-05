{
  lib,
  config,
  ...
}: {
  options.tailscale.enable = lib.mkEnableOption "Enables Tailscale Network.";

  config = lib.mkIf config.tailscale.enable {
    services.tailscale.enable = true;

    networking.firewall.trustedInterfaces = ["tailscale0"];
  };
}
