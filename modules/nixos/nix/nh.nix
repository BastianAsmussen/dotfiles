{userInfo, ...}: {
  programs.nh = {
    enable = true;

    clean = {
      enable = true;

      extraArgs = "--delete-older-than 7d --keep 3";
    };

    flake = "/home/${userInfo.username}/dotfiles";
  };
}
