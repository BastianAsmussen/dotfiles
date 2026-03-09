{
  flake.nixosModules.android = {
    pkgs,
    userInfo,
    ...
  }: {
    environment.systemPackages = [
      pkgs.android-studio
    ];

    programs.java.enable = true;
    users.users.${userInfo.username}.extraGroups = [
      "kvm"
      "adbusers"
    ];
  };
}
