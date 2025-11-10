{
  flake.nixosModules.discord = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      vesktop
      discord
    ];

    persistence.cache.directories = [
      ".config/vesktop"
    ];
  };
}
