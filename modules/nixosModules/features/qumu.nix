{
  flake.nixosModules.qemuVirtualisation = {userInfo, ...}: {
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
