{
  userInfo,
  lib,
  config,
  pkgs,
  ...
}: {
  programs.zsh.enable = true;

  users.users.${userInfo.username} = {
    isNormalUser = true;
    description = userInfo.fullName;
    initialPassword = "Password123!";

    extraGroups = lib.mkMerge [
      ["wheel" "networkmanager"]
      (lib.mkIf config.qemu.enable ["libvirtd"])
      (lib.mkIf (!config.virtualisation.docker.rootless.enable) ["docker"])
    ];
    shell = pkgs.zsh;
  };
}
