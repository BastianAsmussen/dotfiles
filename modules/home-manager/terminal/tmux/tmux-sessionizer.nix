{pkgs, ...}: {
  home = {
    sessionVariables.TMUX_SESSIONIZER_PATHS = "~/Projects ~/dotfiles";
    packages = [pkgs.tmux-sessionizer];
  };
}
