{
  flake.nixosModules.qemu =
    {
      config,
      pkgs,
      ...
    }:
    {
      virtualisation.libvirtd.enable = true;
      environment.systemPackages = [ pkgs.virt-manager ];

      users.users.${config.preferences.user.name}.extraGroups = [ "libvirtd" ];
    };
}
