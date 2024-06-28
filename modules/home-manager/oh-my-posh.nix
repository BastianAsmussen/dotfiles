{pkgs, ...}: {
  programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = true;

    settings = builtins.fromTOML (builtins.unsafeDiscardStringContext (builtins.readFile .config/oh-my-posh/theme.toml));
  };
}
