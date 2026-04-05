{
  flake.nixosModules.wallpaper = {
    pkgs,
    lib,
    ...
  }: {
    preferences.autostart = [
      ''
        ${pkgs.awww}/bin/awww-daemon &
        ${lib.getExe pkgs.awww} img ${../../../assets/wallpapers/tokyo.png} &
      ''
    ];
  };
}
