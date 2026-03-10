{
  flake.nixosModules.nh = {
    config,
    pkgs,
    ...
  }: {
    programs.nh = {
      enable = true;

      flake = "/home/${config.preferences.user.name}/dotfiles";
    };

    environment.systemPackages = with pkgs; [
      nix-output-monitor
      nvd
    ];
  };
}
