{
  flake.nixosModules.youtube-music = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.youtube-music
    ];

    persistence.cache.directories = [
      ".config/YouTube Music"
    ];
  };
}
