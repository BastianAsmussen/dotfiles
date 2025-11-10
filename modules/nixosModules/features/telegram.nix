{
  flake.nixosModules.telegram = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.telegram-desktop
    ];

    persistence.cache.directories = [
      ".local/share/TelegramDesktop"
    ];
  };
}
