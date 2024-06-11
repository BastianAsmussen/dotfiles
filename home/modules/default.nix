{
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ./firefox.nix
    ./fzf.nix
    ./git.nix
    ./nixvim.nix
    ./stylix.nix
    ./tmux.nix
    ./zoxide.nix
    ./zsh.nix
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home = {
    stateVersion = "24.05";

    username = lib.mkDefault "bastian";
    homeDirectory = lib.mkDefault "/home/bastian";

    packages = with pkgs; [
      alacritty
      ripgrep
      htop
      webcord
      gitui
      neofetch
    ];
  };
}
