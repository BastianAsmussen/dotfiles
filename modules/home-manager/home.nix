{
  lib,
  username,
  ...
}: {
  imports = [
    ./nixvim
    ./oh-my-posh
    ./alacritty.nix
    ./firefox.nix
    ./fzf.nix
    ./git.nix
    ./gpg.nix
    ./hyprland.nix
    ./tmux.nix
    ./zoxide.nix
    ./zsh.nix
  ];

  gpg.enable = lib.mkDefault true;

  home = {
    username = "${username}";
    homeDirectory = "/home/${username}";

    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs.
  systemd.user.startServices = "sd-switch";
}
