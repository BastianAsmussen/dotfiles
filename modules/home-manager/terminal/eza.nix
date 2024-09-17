{
  home.shellAliases = {
    ls = "eza";
    tree = "eza --tree";
  };

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
