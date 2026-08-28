{
  flake.homeModules.fzf =
    {
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      cfg = config.programs;
      fd = lib.getExe pkgs.fd;

      fileCommand = "${fd} --type=f --exclude=.git --hidden";

      # home-manager master nests the widget settings; the release branch still
      # uses the flat name. Writing the flat one everywhere works, but trips the
      # rename warning on every unstable host.
      fileWidget =
        if options.programs.fzf ? fileWidget then
          { fileWidget.command = fileCommand; }
        else
          { fileWidgetCommand = fileCommand; };
    in
    {
      programs.fzf = {
        enable = true;
        enableZshIntegration = cfg.zsh.enable;
        enableFishIntegration = cfg.fish.enable;
        tmux.enableShellIntegration = cfg.tmux.enable;
        defaultCommand = "${fd} --type=d --exclude=.git --hidden";
        defaultOptions = [
          "--exact" # Use substring matching by default.
          "--info=inline"
          "--no-mouse"
        ];
      }
      // fileWidget;
    };
}
