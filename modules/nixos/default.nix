{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./crypto
    ./desktop
    ./security
    ./virtualization
    ./home-manager.nix
    ./nix.nix
    ./nvidia.nix
    ./stylix.nix
  ];

  home-manager.enable = lib.mkDefault true;
  stylix.enable = lib.mkDefault true;

  programs.zsh.enable = true;
  users.users.bastian = {
    isNormalUser = true;
    description = "Bastian Asmussen";
    initialPassword = "Password123!";

    extraGroups = ["wheel" "docker" "libvirtd"];
    shell = pkgs.zsh;
  };
}
