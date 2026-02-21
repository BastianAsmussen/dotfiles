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
    ./language.nix
    ./misc.nix
    ./network-manager.nix
    ./nvidia.nix
    ./stylix.nix
    ./user.nix
  ];

  documentation.dev.enable = true;

  btrfs.enable = mkDefault true;
  network-manager.enable = mkDefault true;
  home-manager.enable = mkDefault true;

  system = {
    configurationRevision = toString (self.shortRev or self.dirtyShortRev or self.lastModified or "unknown");
    stateVersion = mkDefault "25.11";
  };
}
