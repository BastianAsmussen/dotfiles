{
  flake.nixosModules.firefox = {pkgs, ...}: {
    programs.firefox.enable = true;

    persistence = {
      data.directories = [".mozilla"];
      cache.directories = [".cache/mozilla"];
    };

    preferences.keymap = {
      "SUPER + d"."f".package = pkgs.firefox;
    };
  };
}
