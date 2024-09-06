{
  lib,
  nixosConfig,
  ...
}: {
  config = lib.mkIf nixosConfig.qemu.enable {
    dconf.settings."org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };
}
