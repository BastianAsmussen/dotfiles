{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs;

  fd = lib.getBin pkgs.fd;
in {
  programs.fzf = {
    enable = true;

    enableZshIntegration = cfg.zsh.enable;
    tmux.enableShellIntegration = cfg.tmux.enable;

    defaultCommand = "${fd} --type=d --exclude=.git --hidden";
    fileWidgetCommand = "${fd} --type=f --exclude=.git --hidden";
    defaultOptions = [
      "--exact" # Use substring matching by default.
      "--info=inline"
      "--no-mouse"
    ];
  };
}
