{self, ...}: {
  flake.nixosModules.desktop = {
    pkgs,
    lib,
    ...
  }: let
    inherit (lib) getExe;

    selfPkgs = self.packages."${pkgs.system}";
  in {
    imports = [
      self.nixosModules.gtk
      self.nixosModules.wallpaper

      self.nixosModules.pipewire
      self.nixosModules.firefox
    ];

    environment.systemPackages = [
      selfPkgs.terminal
      pkgs.pcmanfm
    ];

    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      cm_unicode
      corefonts
    ];

    time.timeZone = "Europe/Copenhagen";
    i18n = {
      defaultLocale = "en_DK.UTF-8";
      extraLocaleSettings = {
        LC_ADDRESS = "en_DK.UTF-8";
        LC_IDENTIFICATION = "en_DK.UTF-8";
        LC_MEASUREMENT = "en_DK.UTF-8";
        LC_MONETARY = "en_DK.UTF-8";
        LC_NAME = "en_DK.UTF-8";
        LC_NUMERIC = "en_DK.UTF-8";
        LC_PAPER = "en_DK.UTF-8";
        LC_TELEPHONE = "en_DK.UTF-8";
        LC_TIME = "en_DK.UTF-8";
      };
    };

    services.upower.enable = true;
    security.polkit.enable = true;
    hardware = {
      enableAllFirmware = true;
      bluetooth = {
        enable = true;
        powerOnBoot = true;
      };

      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };

    preferences.keymap = {
      "SUPERCONTROL + S".exec = ''
        ${getExe pkgs.grim} -l 0 - | ${pkgs.wl-clipboard}/bin/wl-copy'';

      "SUPERSHIFT + E".exec = ''
        ${pkgs.wl-clipboard}/bin/wl-paste | ${getExe pkgs.swappy} -f -
      '';

      "SUPERSHIFT + S".exec = ''
        ${getExe pkgs.grim} -g "$(${getExe pkgs.slurp} -w 0)" - \
        | ${pkgs.wl-clipboard}/bin/wl-copy
      '';

      "SUPER + d"."b".package = pkgs.rofi-bluetooth;
    };
  };
}
