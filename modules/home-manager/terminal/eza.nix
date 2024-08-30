{
  home.shellAliases.ls = "eza";

  programs.eza = {
    enable = true;

    git = true;
    icons = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };
}
