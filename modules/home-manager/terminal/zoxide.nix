{
  home.shellAliases = {
    "cd.." = "cd ..";
    "cd-" = "cd -";
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;

    options = ["--cmd cd"];
  };
}
