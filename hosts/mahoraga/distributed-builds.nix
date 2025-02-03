{pkgs, ...}: {
  nix.buildMachines = [
    {
      inherit (pkgs.stdenv.hostPlatform) system;

      hostName = "builder";
      protocol = "ssh-ng";
      speedFactor = 2;

      supportedFeatures = ["nixos-test" "big-parallel" "kvm"];
    }
  ];
}
