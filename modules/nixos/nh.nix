{config, ...}: {
  programs.nh = {
    enable = true;

    clean = {
      enable = true;

      extraArgs = "--delete-older-than 4d --keep 3";
    };

    flake = "/home/${config.home-manager.username}/dotfiles";
  };
}
