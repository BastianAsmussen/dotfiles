{
  lib,
  config,
  userInfo,
  ...
}: {
  options.qemu.enable = lib.mkEnableOption "Enables QEMU virtualisation.";

  config = lib.mkIf config.qemu.enable {
    virtualisation.libvirtd.enable = true;
    users.extraGroups.libvirt.members = [userInfo.username];

    programs.virt-manager.enable = true;
  };
}
