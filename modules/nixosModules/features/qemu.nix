{
  flake.nixosModules.qemuVirtualisation = {config, ...}: {
    virtualisation.libvirtd.enable = true;
    users.extraGroups.libvirt.members = [config.preferences.user.name];

    boot.binfmt.emulatedSystems = [
      "aarch64-linux"
      "i686-linux"
      "riscv64-linux"
    ];

    programs.virt-manager.enable = true;
  };
}
