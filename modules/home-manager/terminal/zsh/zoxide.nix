{config, ...}: {
  home.shellAliases."cd.." = "cd ..";

  programs.zoxide = {
    enable = true;

    enableZshIntegration = config.programs.zsh.enable;
    options = ["--cmd cd"];
  };
}
