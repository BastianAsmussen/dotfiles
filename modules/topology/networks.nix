# The two networks hosts attach to. Hosts pick one by name in `topology.self`.
{ inputs, ... }:
{
  perSystem = {
    topology.modules = [
      {
        networks = {
          home = {
            name = "Home Network";
            cidrv4 = "192.168.1.0/24";
          };

          cloud = {
            name = "Hetzner Network";
            cidrv4 = "${inputs.nix-secrets.hosts.eta.ipv4_address}/32";
            cidrv6 = "2a01:4f8:c014:4725::/64";
          };
        };
      }
    ];
  };
}
