{ self, ... }:
{
  flake.nixosModules.virtualisation =
    { pkgs, ... }:
    {
      imports = [
        self.nixosModules.android
        self.nixosModules.podman
        self.nixosModules.qemu
      ];

      # Emulate ARM CPU.
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

      # Bottles.
      environment.systemPackages = [ pkgs.bottles ];
    };
}
