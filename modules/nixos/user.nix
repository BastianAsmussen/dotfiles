{pkgs, ...}: {
  programs.zsh.enable = true;

  users.users.bastian = {
    isNormalUser = true;
    description = "Bastian Asmussen";
    initialPassword = "Password123!";

    extraGroups = ["wheel" "docker" "libvirtd" "networkmanager"];
    shell = pkgs.zsh;
  };
}
