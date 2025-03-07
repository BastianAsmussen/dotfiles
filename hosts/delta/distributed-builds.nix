{pkgs, ...}: {
  nix.buildMachines = [
    {
      inherit (pkgs.stdenv.hostPlatform) system;

      hostName = "builder";
      protocol = "ssh-ng";
      speedFactor = 10;

      supportedFeatures = ["nixos-test" "big-parallel" "kvm"];
    }
  ];
}
