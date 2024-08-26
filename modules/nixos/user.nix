{
  lib,
  config,
  pkgs,
  ...
}: {
  programs.zsh.enable = true;

  users.users.bastian = {
    isNormalUser = true;
    description = "Bastian Asmussen";
    initialPassword = "Password123!";

    extraGroups = lib.mkMerge [
      ["wheel" "networkmanager"]
      (lib.mkIf config.qemu.enable ["libvirtd"])
      (lib.mkIf (!config.virtualisation.docker.rootless.enable) ["docker"])
    ];
    shell = pkgs.zsh;
  };
}
