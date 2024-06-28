{
  config,
  pkgs,
  ...
}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    history = {
      size = 10000;
      history.path = "${config.xdg.dataHome}/zsh/history";
    };

    shellAliases = {
      vi = "vim";
      vim = "nvim";

      ls = "ls --color";
      c = "clear";

      cp = "cp -r";
      rm = "rm -r";
    };
  };
}
