{
  flake.nixosModules.nh = {
    userInfo,
    pkgs,
    ...
  }: {
    programs.nh = {
      enable = true;

      flake = "/home/${userInfo.username}/dotfiles";
    };

    environment.systemPackages = with pkgs; [
      nix-output-monitor
      nvd
    ];
  };
}
