{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware.nix
    ./disko.nix

    ../common
  ];

  system.stateVersion = "24.05";

  networking.hostName = "limitless";
  nix.gc.options = lib.mkForce "--delete-older-than 14d";

  custom = {
    gaming.enable = true;
    nvidia.enable = true;
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override {
      fonts = ["JetBrainsMono"];
    })
  ];

  environment.systemPackages = with pkgs; [
    git
    cachix
  ];
}
