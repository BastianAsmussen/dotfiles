{config, ...}: let
  cfg = config.programs;
in {
  programs.fzf = {
    enable = true;

    enableZshIntegration = cfg.zsh.enable;
    tmux.enableShellIntegration = cfg.tmux.enable;
  };
}
