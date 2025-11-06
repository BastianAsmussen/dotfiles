{
  flake.nixosModules.gimp = {pkgs, ...}: {
    environment.systemPackages = [pkgs.gimp3];
    persistence.cache.directories = [
      ".config/GIMP"
    ];
  };
}
