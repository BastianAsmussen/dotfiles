{
  lib,
  pkgs,
  ...
}: 
let
  goxlr-rules = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/GoXLR-on-Linux/goxlr-utility/main/50-goxlr.rules";
    sha256 = "0cr2ky1hd0p3d4zqqvi7axn952gyiljgvrrqcnlnjcy9h7zwx5cm";
  };
in {
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
    goxlr-utility
  ];

  services.udev.extraRules = builtins.readFile goxlr-rules;
}

