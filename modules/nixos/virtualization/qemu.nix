{
  lib,
  config,
  ...
}: {
  options.qemu.enable = lib.mkEnableOption "Enables QEMU virtualization.";

  config = lib.mkIf config.qemu.enable {
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
  };
}
