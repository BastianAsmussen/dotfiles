{
  programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = true;

    settings = builtins.fromTOML (builtins.readFile ./theme.toml);
  };
}
