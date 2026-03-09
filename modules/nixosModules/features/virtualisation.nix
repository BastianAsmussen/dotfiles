{self, ...}: {
  flake.nixosModules.virtualisation = {pkgs, ...}: {
    imports = [
      self.nixosModules.android
      self.nixosModules.docker
      # self.nixosModules.qemuVirtualisation
    ];

    # Bottles.
    environment.systemPackages = [pkgs.bottles];
  };
}
