{
  flake.nixosModules.language = {pkgs, ...}: {
    time.timeZone = "Europe/Copenhagen";
    i18n = let
      locale = "en_DK.UTF-8";
    in {
      defaultLocale = locale;
      extraLocales = [
        "en_US.UTF-8/UTF-8"
        "en_DK.UTF-8/UTF-8"
        "da_DK.UTF-8/UTF-8"
      ];

      extraLocaleSettings = {
        LC_ADDRESS = locale;
        LC_IDENTIFICATION = locale;
        LC_MEASUREMENT = locale;
        LC_MONETARY = locale;
        LC_NAME = locale;
        LC_NUMERIC = locale;
        LC_PAPER = locale;
        LC_TELEPHONE = locale;
        LC_TIME = locale;
      };
    };

    console.useXkbConfig = true;
    services.xserver.xkb.layout = "dk";

    environment.systemPackages = with pkgs; [
      hunspellDicts.da_DK
    ];

    fonts.packages = with pkgs; [
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
    ];
  };
}
