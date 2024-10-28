{
  home.shellAliases = {
    ls = "eza";
    tree = "eza --tree";
  };

  programs.eza = {
    enable = true;

    git = true;
    icons = "always";
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };
}
