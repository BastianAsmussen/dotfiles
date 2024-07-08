{lib, ...}: {
  imports = [
    ./audio.nix
    ./home-manager.nix
    ./hyprland.nix
    ./nix.nix
    ./nvidia.nix
    ./sddm.nix
    ./security.nix
    ./stylix.nix
    ./user.nix
  ];

  audio.enable = lib.mkDefault true;

  home-manager.enable = lib.mkDefault true;

  hyprland.enable = lib.mkDefault true;

  sddm.enable = lib.mkDefault true;

  gpg.enable = lib.mkDefault true;
  vpn.enable = lib.mkDefault true;
  yubiKey.enable = lib.mkDefault true;

  stylix.enable = lib.mkDefault true;
}
