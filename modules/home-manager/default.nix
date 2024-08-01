{
  lib,
  username,
  pkgs,
  ...
}: {
  imports = [
    ./hyprland
    ./nixvim
    ./oh-my-posh
    ./zsh
    ./alacritty.nix
    ./btop.nix
    ./development.nix
    ./eza.nix
    ./fastfetch.nix
    ./firefox.nix
    ./fzf.nix
    ./git.nix
    ./gpg.nix
    ./nixcord.nix
    ./tmux.nix
    ./zoxide.nix
  ];

  gpg.enable = lib.mkDefault true;

  home = {
    username = "${username}";
    homeDirectory = "/home/${username}";

    packages = with pkgs; [
      ripgrep
      gitui
      wget
      go
      manix
    ];

    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs.
  systemd.user.startServices = "sd-switch";
}
