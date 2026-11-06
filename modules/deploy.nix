{ inputs, self, ... }:
{
  flake.deploy.nodes.eta = {
    hostname = "10.10.0.1";
    profiles.system = {
      sshUser = "root";
      user = "root";
      path = inputs.deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.eta;
    };
  };
}
