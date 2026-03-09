{
  flake.nixosModules.tailscale = {
    services.tailscale.enable = true;

    networking.firewall.trustedInterfaces = ["tailscale0"];
  };
}
