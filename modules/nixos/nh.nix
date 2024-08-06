{
  programs.nh = {
    enable = true;

    clean = {
      enable = true;

      extraArgs = "--delete-older-than 7d";
    };
  };
}
