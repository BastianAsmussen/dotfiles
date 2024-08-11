{pkgs, ...}: {
  home.packages = [pkgs.devenv];

  programs.direnv = {
    enable = true;

    nix-direnv.enable = true;
    silent = true;

    enableZshIntegration = true;
  };
}
