{
  lib,
  config,
  pkgs,
  userInfo,
  ...
}: {
  options.android.enable = lib.mkEnableOption "Enables Android emulation.";

  config = lib.mkIf config.qemu.enable {
    environment.systemPackages = [
      pkgs.android-studio
    ];

    programs.java.enable = true;
    users.users.${userInfo.username}.extraGroups = [
      "kvm" # Hardware acceleration.
      "adbusers" # Access to the Android Debugger Bridge.
    ];
  };
}
