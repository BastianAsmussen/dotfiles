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

      # HM master renamed this to fileWidget and warns on the flat name.
      fileWidget =
        if options.programs.fzf ? fileWidget then
          { fileWidget.command = fileCommand; }
        else
          { fileWidgetCommand = fileCommand; };
    in
    {
      programs.fzf = {
        enable = true;
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
