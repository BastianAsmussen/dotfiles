{
  flake.nixosModules.nh = {
    config,
    pkgs,
    ...
  }: {
    programs.nh = {
      enable = true;

      flake = "/home/${config.preferences.user.name}/dotfiles";

      clean = {
        enable = true;
        extraArgs = "--keep 3 --keep-since 7d";
      };
    };

    environment.systemPackages = with pkgs; [
      nix-output-monitor
      nvd
    ];
  };
}
