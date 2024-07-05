{...}: {
  imports = [
    ./alacritty.nix
    ./firefox.nix
    ./fzf.nix
    ./git.nix
    ./oh-my-posh.nix
    ./tmux.nix
    ./zoxide.nix
    ./zsh.nix
  ];

  home = {
    username = "bastian";
    homeDirectory = "/home/bastian";

    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs.
  systemd.user.startServices = "sd-switch";
}
