{pkgs, ...}: {
  home.packages = [pkgs.devenv];

  programs.direnv = {
    enable = true;

    nix-direnv.enable = true;
    silent = true;

    enableZshIntegration = true;
  };

  nix.settings = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };
}
