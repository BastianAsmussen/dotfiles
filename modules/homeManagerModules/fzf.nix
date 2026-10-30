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

      fdWithArgs = args: "${lib.getExe pkgs.fd} ${args}";
      fdCmd = fdWithArgs "--type=f --exclude=.git --hidden";

      # home-manager master nests the widget settings; the release branch still
      # uses the flat name. Writing the flat one everywhere works, but trips the
      # rename warning on every unstable host.
      fileWidget =
        if options.programs.fzf ? fileWidget then
          { fileWidget.command = fdCmd; }
        else
          { fileWidgetCommand = fdCmd; };
    in
    {
      programs.fzf = {
        enable = true;
        tmux.enableShellIntegration = cfg.tmux.enable;
        defaultCommand = fdWithArgs "--type=d --exclude=.git --hidden";
        defaultOptions = [
          "--exact" # Use substring matching by default.
          "--info=inline"
          "--no-mouse"
        ];
      }
      // fileWidget;
    };
}
