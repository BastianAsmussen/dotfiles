{
  lib,
  self,
  ...
}: let
  inherit (lib) mkDefault;
in {
  imports = [
    ./crypto
    ./desktop
    ./nix
    ./security
    ./virtualisation
    ./bluetooth.nix
    ./bootloader.nix
    ./btrfs.nix
    ./gaming.nix
    ./goxlr.nix
    ./home-manager.nix
    ./ipfs.nix
    ./language.nix
    ./misc.nix
    ./network-manager.nix
    ./nvidia.nix
    ./sops.nix
    ./stylix.nix
    ./user.nix
    ./vaultwarden.nix
  ];

  documentation.dev.enable = true;

  btrfs.enable = mkDefault true;
  network-manager.enable = mkDefault true;
  home-manager.enable = mkDefault true;

  system = {
    configurationRevision = self.shortRev or self.dirtyShortRev;
    stateVersion = mkDefault "24.05";
  };
}
