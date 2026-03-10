{
  flake.nixosModules.android = {
    pkgs,
    config,
    ...
  }: {
    environment.systemPackages = [
      pkgs.android-studio
    ];

    programs.java.enable = true;
    users.users.${config.preferences.user.name}.extraGroups = [
      "kvm"
      "adbusers"
    ];
  };
}
