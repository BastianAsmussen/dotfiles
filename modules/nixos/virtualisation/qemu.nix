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

    boot.binfmt.emulatedSystems = [
      "aarch64-linux"
      "i686-linux"
      "riscv64-linux"
    ];

    programs.virt-manager.enable = true;
  };
}
